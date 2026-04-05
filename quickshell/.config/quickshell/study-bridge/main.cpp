#include <iostream>
#include <sqlite3.h>
#include <nlohmann/json.hpp>
#include <vector>
#include <string>
#include <filesystem>

using json = nlohmann::json;
namespace fs = std::filesystem;

class StudyDB {
public:
    StudyDB(const std::string& path) {
        if (sqlite3_open(path.c_str(), &db) != SQLITE_OK) {
            throw std::runtime_error("Cannot open database: " + std::string(sqlite3_errmsg(db)));
        }
        sqlite3_busy_timeout(db, 5000); // 5s timeout
        init();
    }

    ~StudyDB() {
        sqlite3_close(db);
    }

    void init() {
        const char* sql = 
            "CREATE TABLE IF NOT EXISTS subjects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, rating INTEGER DEFAULT 0);"
            "CREATE TABLE IF NOT EXISTS topics (id INTEGER PRIMARY KEY AUTOINCREMENT, subject_id INTEGER, name TEXT, display_order INTEGER, FOREIGN KEY(subject_id) REFERENCES subjects(id));"
            "CREATE TABLE IF NOT EXISTS progress (topic_id INTEGER PRIMARY KEY, c1 BOOLEAN DEFAULT 0, c2 BOOLEAN DEFAULT 0, c3 BOOLEAN DEFAULT 0, c4 BOOLEAN DEFAULT 0, FOREIGN KEY(topic_id) REFERENCES topics(id));"
            "CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT, completed BOOLEAN DEFAULT 0, display_order INTEGER);"
            "CREATE TABLE IF NOT EXISTS study_history (date TEXT PRIMARY KEY, seconds INTEGER DEFAULT 0);";
        
        char* errMsg = nullptr;
        if (sqlite3_exec(db, sql, nullptr, nullptr, &errMsg) != SQLITE_OK) {
            std::string err = errMsg;
            sqlite3_free(errMsg);
            throw std::runtime_error("SQL error during init: " + err);
        }
        // Migration for existing databases
        sqlite3_exec(db, "ALTER TABLE subjects ADD COLUMN rating INTEGER DEFAULT 0;", nullptr, nullptr, nullptr);
    }

    json getDashboardStats() {
        json result;
        
        // 1. Subject Stats
        const char* subSql = 
            "SELECT s.id, s.name, s.rating, "
            "  (SELECT COUNT(*) FROM topics t JOIN progress p ON t.id = p.topic_id WHERE t.subject_id = s.id AND p.c1 = 1) as completed, "
            "  (SELECT COUNT(*) FROM topics t WHERE t.subject_id = s.id) as total "
            "FROM subjects s;";
        
        sqlite3_stmt* stmt;
        result["subjects"] = json::array();
        if (sqlite3_prepare_v2(db, subSql, -1, &stmt, nullptr) == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                json sub;
                sub["id"] = sqlite3_column_int(stmt, 0);
                sub["name"] = (const char*)sqlite3_column_text(stmt, 1);
                sub["rating"] = sqlite3_column_int(stmt, 2);
                sub["completed"] = sqlite3_column_int(stmt, 3);
                sub["total"] = sqlite3_column_int(stmt, 4);
                result["subjects"].push_back(sub);
            }
            sqlite3_finalize(stmt);
        }

        // 2. 7-Day History
        result["history"] = json::array();
        for (int i = 6; i >= 0; --i) {
            const char* histSql = "SELECT seconds FROM study_history WHERE date = date('now', 'localtime', ?);";
            if (sqlite3_prepare_v2(db, histSql, -1, &stmt, nullptr) == SQLITE_OK) {
                std::string offset = "-" + std::to_string(i) + " days";
                sqlite3_bind_text(stmt, 1, offset.c_str(), -1, SQLITE_STATIC);
                
                int seconds = 0;
                if (sqlite3_step(stmt) == SQLITE_ROW) {
                    seconds = sqlite3_column_int(stmt, 0);
                }
                
                json day;
                // Get day name for UI
                const char* dayNameSql = "SELECT strftime('%w', 'now', 'localtime', ?);";
                sqlite3_stmt* nameStmt;
                std::string dayName = "?";
                if (sqlite3_prepare_v2(db, dayNameSql, -1, &nameStmt, nullptr) == SQLITE_OK) {
                    sqlite3_bind_text(nameStmt, 1, offset.c_str(), -1, SQLITE_STATIC);
                    if (sqlite3_step(nameStmt) == SQLITE_ROW) {
                        int dayIdx = sqlite3_column_int(nameStmt, 0);
                        const char* days[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
                        dayName = days[dayIdx];
                    }
                    sqlite3_finalize(nameStmt);
                }

                day["day"] = dayName;
                day["seconds"] = seconds;
                result["history"].push_back(day);
                sqlite3_finalize(stmt);
            }
        }
        
        return result;
    }

    void updateRating(int subjectId, int rating) {
        const char* sql = "UPDATE subjects SET rating = ? WHERE id = ?;";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, rating);
            sqlite3_bind_int(stmt, 2, subjectId);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    void logStudyTime(int seconds) {
        const char* checkSql = "INSERT OR IGNORE INTO study_history (date, seconds) VALUES (date('now', 'localtime'), 0);";
        sqlite3_exec(db, checkSql, nullptr, nullptr, nullptr);

        const char* sql = "UPDATE study_history SET seconds = seconds + ? WHERE date = date('now', 'localtime');";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, seconds);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    json getTodos() {
        const char* sql = "SELECT id, task, completed FROM todos ORDER BY display_order;";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
            std::cerr << "Prepare error: " << sqlite3_errmsg(db) << std::endl;
            return json::array();
        }

        json result = json::array();
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            json todo;
            todo["id"] = sqlite3_column_int(stmt, 0);
            todo["task"] = (const char*)sqlite3_column_text(stmt, 1);
            todo["completed"] = (bool)sqlite3_column_int(stmt, 2);
            result.push_back(todo);
        }
        sqlite3_finalize(stmt);
        return result;
    }

    void addTodo(const std::string& task) {
        const char* orderSql = "SELECT COUNT(*) FROM todos;";
        sqlite3_stmt* stmt;
        int order = 0;
        if (sqlite3_prepare_v2(db, orderSql, -1, &stmt, nullptr) == SQLITE_OK) {
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                order = sqlite3_column_int(stmt, 0);
            }
            sqlite3_finalize(stmt);
        }

        const char* sql = "INSERT INTO todos (task, display_order) VALUES (?, ?);";
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, task.c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 2, order);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    void updateTodo(int id, bool completed) {
        const char* sql = "UPDATE todos SET completed = ? WHERE id = ?;";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, completed ? 1 : 0);
            sqlite3_bind_int(stmt, 2, id);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    void renameTodo(int id, const std::string& newTask) {
        const char* sql = "UPDATE todos SET task = ? WHERE id = ?;";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, newTask.c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 2, id);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    void deleteTodo(int id) {
        const char* sql = "DELETE FROM todos WHERE id = ?;";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, id);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    json getSubjectData(const std::string& subjectName) {
        const char* sql = "SELECT id FROM subjects WHERE name = ?;";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) != SQLITE_OK) {
            std::cerr << "Prepare error: " << sqlite3_errmsg(db) << std::endl;
            return json::array();
        }
        sqlite3_bind_text(stmt, 1, subjectName.c_str(), -1, SQLITE_STATIC);

        int subjectId = -1;
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            subjectId = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);

        if (subjectId == -1) return json::array();

        const char* query = 
            "SELECT t.id, t.name, p.c1, p.c2, p.c3, p.c4 "
            "FROM topics t "
            "LEFT JOIN progress p ON t.id = p.topic_id "
            "WHERE t.subject_id = ? "
            "ORDER BY t.display_order;";

        if (sqlite3_prepare_v2(db, query, -1, &stmt, nullptr) != SQLITE_OK) {
            std::cerr << "Prepare error: " << sqlite3_errmsg(db) << std::endl;
            return json::array();
        }
        sqlite3_bind_int(stmt, 1, subjectId);

        json result = json::array();
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            json topic;
            topic["id"] = sqlite3_column_int(stmt, 0);
            topic["name"] = (const char*)sqlite3_column_text(stmt, 1);
            topic["checked"] = {
                (bool)sqlite3_column_int(stmt, 2),
                (bool)sqlite3_column_int(stmt, 3),
                (bool)sqlite3_column_int(stmt, 4),
                (bool)sqlite3_column_int(stmt, 5)
            };
            result.push_back(topic);
        }
        sqlite3_finalize(stmt);
        return result;
    }

    void updateProgress(int topicId, int colIdx, bool val) {
        const char* insertSql = "INSERT OR IGNORE INTO progress (topic_id) VALUES (?);";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, insertSql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, topicId);
            if (sqlite3_step(stmt) != SQLITE_DONE) {
                std::cerr << "Insert error: " << sqlite3_errmsg(db) << std::endl;
            }
            sqlite3_finalize(stmt);
        } else {
            std::cerr << "Prepare error: " << sqlite3_errmsg(db) << std::endl;
        }

        std::string colName = "c" + std::to_string(colIdx + 1);
        std::string updateSql = "UPDATE progress SET " + colName + " = ? WHERE topic_id = ?;";
        
        if (sqlite3_prepare_v2(db, updateSql.c_str(), -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, val ? 1 : 0);
            sqlite3_bind_int(stmt, 2, topicId);
            if (sqlite3_step(stmt) != SQLITE_DONE) {
                std::cerr << "Update error: " << sqlite3_errmsg(db) << std::endl;
            }
            sqlite3_finalize(stmt);
        } else {
            std::cerr << "Prepare error: " << sqlite3_errmsg(db) << std::endl;
        }
    }

    void addTopic(const std::string& subjectName, const std::string& topicName) {
        const char* subSql = "INSERT OR IGNORE INTO subjects (name) VALUES (?);";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, subSql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, subjectName.c_str(), -1, SQLITE_STATIC);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }

        const char* getIdSql = "SELECT id FROM subjects WHERE name = ?;";
        int subjectId = -1;
        if (sqlite3_prepare_v2(db, getIdSql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, subjectName.c_str(), -1, SQLITE_STATIC);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                subjectId = sqlite3_column_int(stmt, 0);
            }
            sqlite3_finalize(stmt);
        }

        if (subjectId == -1) return;

        const char* orderSql = "SELECT COUNT(*) FROM topics WHERE subject_id = ?;";
        int order = 0;
        if (sqlite3_prepare_v2(db, orderSql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, subjectId);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                order = sqlite3_column_int(stmt, 0);
            }
            sqlite3_finalize(stmt);
        }

        const char* insTopicSql = "INSERT INTO topics (subject_id, name, display_order) VALUES (?, ?, ?);";
        if (sqlite3_prepare_v2(db, insTopicSql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, subjectId);
            sqlite3_bind_text(stmt, 2, topicName.c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 3, order);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    void renameTopic(int topicId, const std::string& newName) {
        const char* sql = "UPDATE topics SET name = ? WHERE id = ?;";
        sqlite3_stmt* stmt;
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, newName.c_str(), -1, SQLITE_STATIC);
            sqlite3_bind_int(stmt, 2, topicId);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

    void deleteTopic(int topicId) {
        const char* sql1 = "DELETE FROM progress WHERE topic_id = ?;";
        const char* sql2 = "DELETE FROM topics WHERE id = ?;";
        sqlite3_stmt* stmt;
        
        if (sqlite3_prepare_v2(db, sql1, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, topicId);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }

        if (sqlite3_prepare_v2(db, sql2, -1, &stmt, nullptr) == SQLITE_OK) {
            sqlite3_bind_int(stmt, 1, topicId);
            sqlite3_step(stmt);
            sqlite3_finalize(stmt);
        }
    }

private:
    sqlite3* db;
};

int main(int argc, char* argv[]) {
    if (argc < 2) return 1;

    std::string dbPath = std::string(getenv("HOME")) + "/dotfiles/quickshell/.config/quickshell/study.db";
    
    try {
        StudyDB sdb(dbPath);
        std::string cmd = argv[1];

        if (cmd == "get" && argc == 3) {
            std::cout << sdb.getSubjectData(argv[2]).dump() << std::endl;
        } else if (cmd == "update" && argc == 5) {
            sdb.updateProgress(std::stoi(argv[2]), std::stoi(argv[3]), std::string(argv[4]) == "true");
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "add" && argc == 4) {
            sdb.addTopic(argv[2], argv[3]);
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "rename" && argc == 4) {
            sdb.renameTopic(std::stoi(argv[2]), argv[3]);
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "delete" && argc == 3) {
            sdb.deleteTopic(std::stoi(argv[2]));
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "get_todos" && argc == 2) {
            std::cout << sdb.getTodos().dump() << std::endl;
        } else if (cmd == "add_todo" && argc == 3) {
            sdb.addTodo(argv[2]);
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "update_todo" && argc == 4) {
            sdb.updateTodo(std::stoi(argv[2]), std::string(argv[3]) == "true");
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "rename_todo" && argc == 4) {
            sdb.renameTodo(std::stoi(argv[2]), argv[3]);
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "delete_todo" && argc == 3) {
            sdb.deleteTodo(std::stoi(argv[2]));
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "get_dashboard_stats" && argc == 2) {
            std::cout << sdb.getDashboardStats().dump() << std::endl;
        } else if (cmd == "update_rating" && argc == 4) {
            sdb.updateRating(std::stoi(argv[2]), std::stoi(argv[3]));
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        } else if (cmd == "log_study_time" && argc == 3) {
            sdb.logStudyTime(std::stoi(argv[2]));
            std::cout << "{\"status\":\"ok\"}" << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
