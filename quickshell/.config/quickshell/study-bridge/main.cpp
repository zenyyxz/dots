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
        init();
    }

    ~StudyDB() {
        sqlite3_close(db);
    }

    void init() {
        const char* sql = 
            "CREATE TABLE IF NOT EXISTS subjects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE);"
            "CREATE TABLE IF NOT EXISTS topics (id INTEGER PRIMARY KEY AUTOINCREMENT, subject_id INTEGER, name TEXT, display_order INTEGER, FOREIGN KEY(subject_id) REFERENCES subjects(id));"
            "CREATE TABLE IF NOT EXISTS progress (topic_id INTEGER PRIMARY KEY, c1 BOOLEAN DEFAULT 0, c2 BOOLEAN DEFAULT 0, c3 BOOLEAN DEFAULT 0, c4 BOOLEAN DEFAULT 0, FOREIGN KEY(topic_id) REFERENCES topics(id));";
        
        char* errMsg = nullptr;
        if (sqlite3_exec(db, sql, nullptr, nullptr, &errMsg) != SQLITE_OK) {
            std::string err = errMsg;
            sqlite3_free(errMsg);
            throw std::runtime_error("SQL error during init: " + err);
        }
    }

    json getSubjectData(const std::string& subjectName) {
        const char* sql = "SELECT id FROM subjects WHERE name = ?;";
        sqlite3_stmt* stmt;
        sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
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

        sqlite3_prepare_v2(db, query, -1, &stmt, nullptr);
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
        sqlite3_prepare_v2(db, insertSql, -1, &stmt, nullptr);
        sqlite3_bind_int(stmt, 1, topicId);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);

        std::string colName = "c" + std::to_string(colIdx + 1);
        std::string updateSql = "UPDATE progress SET " + colName + " = ? WHERE topic_id = ?;";
        
        sqlite3_prepare_v2(db, updateSql.c_str(), -1, &stmt, nullptr);
        sqlite3_bind_int(stmt, 1, val ? 1 : 0);
        sqlite3_bind_int(stmt, 2, topicId);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }

    void addTopic(const std::string& subjectName, const std::string& topicName) {
        const char* subSql = "INSERT OR IGNORE INTO subjects (name) VALUES (?);";
        sqlite3_stmt* stmt;
        sqlite3_prepare_v2(db, subSql, -1, &stmt, nullptr);
        sqlite3_bind_text(stmt, 1, subjectName.c_str(), -1, SQLITE_STATIC);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);

        const char* getIdSql = "SELECT id FROM subjects WHERE name = ?;";
        sqlite3_prepare_v2(db, getIdSql, -1, &stmt, nullptr);
        sqlite3_bind_text(stmt, 1, subjectName.c_str(), -1, SQLITE_STATIC);
        sqlite3_step(stmt);
        int subjectId = sqlite3_column_int(stmt, 0);
        sqlite3_finalize(stmt);

        const char* orderSql = "SELECT COUNT(*) FROM topics WHERE subject_id = ?;";
        sqlite3_prepare_v2(db, orderSql, -1, &stmt, nullptr);
        sqlite3_bind_int(stmt, 1, subjectId);
        sqlite3_step(stmt);
        int order = sqlite3_column_int(stmt, 0);
        sqlite3_finalize(stmt);

        const char* insTopicSql = "INSERT INTO topics (subject_id, name, display_order) VALUES (?, ?, ?);";
        sqlite3_prepare_v2(db, insTopicSql, -1, &stmt, nullptr);
        sqlite3_bind_int(stmt, 1, subjectId);
        sqlite3_bind_text(stmt, 2, topicName.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 3, order);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }

    void renameTopic(int topicId, const std::string& newName) {
        const char* sql = "UPDATE topics SET name = ? WHERE id = ?;";
        sqlite3_stmt* stmt;
        sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr);
        sqlite3_bind_text(stmt, 1, newName.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 2, topicId);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }

    void deleteTopic(int topicId) {
        const char* sql1 = "DELETE FROM progress WHERE topic_id = ?;";
        const char* sql2 = "DELETE FROM topics WHERE id = ?;";
        sqlite3_stmt* stmt;
        
        sqlite3_prepare_v2(db, sql1, -1, &stmt, nullptr);
        sqlite3_bind_int(stmt, 1, topicId);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);

        sqlite3_prepare_v2(db, sql2, -1, &stmt, nullptr);
        sqlite3_bind_int(stmt, 1, topicId);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
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
        }
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
