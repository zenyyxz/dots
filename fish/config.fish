if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
    
    # Initialize Starship
    starship init fish | source
    
    # FZF configuration
    set -gx FZF_DEFAULT_COMMAND "fd --type f"
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    
    # Aliases
    alias clear "printf '\033[2J\033[3J\033[1;1H'" # fix: kitty doesn't clear properly
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    
    # Check for eza and use it for ls if available
    if command -v eza > /dev/null
        alias ls 'eza --icons'
        alias ll 'eza -lh --icons'
        alias la 'eza -a --icons'
    else
        alias ls 'ls --color=auto'
        alias ll 'ls -lh'
        alias la 'ls -A'
    end
    
    alias pamcan 'pacman'
end

# Environment variables
set -gx EDITOR code
set -gx VISUAL code

# opencode
fish_add_path /home/zenyyxz/.opencode/bin
