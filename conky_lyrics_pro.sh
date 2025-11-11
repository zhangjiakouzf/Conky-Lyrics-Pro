##!/usr/bin/env bash
# =============================================================================
# Conky Lyrics Pro - 专业级桌面歌词显示器
# 作者: miles
# 特性: 同步高亮 + 缓存 + 多版本切换 + 字体调节 + 拖动定位 + 位置记忆
# 依赖: conky, playerctl, curl, jq, sqlite3 
# =============================================================================

# define variables and alias
# {{{
APP_NAME="Conky-Lyrics-Pro"
APP_VERSION="1.2-20251111"
APP_RUNTIME_DIR="$HOME/.cache/$APP_NAME"
APP_PIPE_FILE="$APP_RUNTIME_DIR/$APP_NAME.pipe"
APP_DB_FILE="$APP_RUNTIME_DIR/$APP_NAME.db"
APP_LRC_DIR="$APP_RUNTIME_DIR/lrc/"
APP_CUSTOMIZATION="$APP_RUNTIME_DIR/Customization"
APP_CURL_TIMEOUT=30
APP_CURL_COMMAND="curl -s -L --max-time $APP_CURL_TIMEOUT \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' \
  -H 'Accept-Encoding: gzip, deflate, br' \
  -H 'Connection: keep-alive' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'Sec-Fetch-Dest: document' \
  -H 'Sec-Fetch-Mode: navigate' \
  -H 'Sec-Fetch-Site: none' \
  -H 'Sec-Fetch-User: ?1' \
  -H 'Cache-Control: max-age=0' \
  --compressed \
  "
MUSIC_TRACK=""
MUSIC_ARTIST=""
MUSIC_ALBUM=""
MUSIC_LENGTH=""
MUSIC_OFFSET=0

PLAY_NEW_MUSIC=0

LYRICS_JS_RESPONSE=""
declare -a LYRICS_ARRAY_SYNCEDLYRICS
LYRICS_ARRAY_INDEX=0
LYRICS_ARRAY_COUNT=0
LYRICS_DISPLAY_CONTENT=""
LYRICS_DB_CONTENT=""

LYRICS_JS_SEARCH_RESPONSE=""
declare -a LYRICS_SEARCH_ARRAY_SYNCEDLYRICS
LYRICS_SEARCH_ARRAY_COUNT=0

CONKY_FONT_SIZE=20
CONKY_RUNNING="no"

# 关键：启用 alias 扩展
shopt -s expand_aliases
#alias ctrl_client='playerctl -p spotify'
alias ctrl_client='playerctl '
# }}}

# Define functions for utils (ie. logging, special print)
# {{{
# ═══════════════════════════════════════════════════════════
# 终极全大写英文助记符版（最易懂！一眼认色！）
# ═══════════════════════════════════════════════════════════

# 标准色（全大写英文，超好记）
RED="\e[31m";       GREEN="\e[32m";     YELLOW="\e[33m"
BLUE="\e[34m";      MAGENTA="\e[35m";   CYAN="\e[36m"
WHITE="\e[37m";     BLACK="\e[30m"

# 单字母简写（敲得飞快）
R="${RED}"; G="${GREEN}"; Y="${YELLOW}"; B="${BLUE}"
M="${MAGENTA}"; C="${CYAN}"; W="${WHITE}"; K="${BLACK}"

# 高亮版（BOLD_ 前缀）
BOLD="\e[1m"
BOLD_RED="\e[1;31m";    BOLD_GREEN="\e[1;32m";   BOLD_YELLOW="\e[1;33m"
BOLD_BLUE="\e[1;34m";   BOLD_MAGENTA="\e[1;35m"; BOLD_CYAN="\e[1;36m"
BOLD_WHITE="\e[1;37m";  BOLD_BLACK="\e[1;30m"

# 简写高亮
BR="${BOLD_RED}"; BG="${BOLD_GREEN}"; BY="${BOLD_YELLOW}"
BB="${BOLD_BLUE}"; BM="${BOLD_MAGENTA}"; BC="${BOLD_CYAN}"
BW="${BOLD_WHITE}"; BK="${BOLD_BLACK}"

# 背景色（BG_ 前缀）
BG_RED="\e[41m";    BG_GREEN="\e[42m";    BG_YELLOW="\e[43m"
BG_BLUE="\e[44m";   BG_MAGENTA="\e[45m";  BG_CYAN="\e[46m"
BG_WHITE="\e[47m";  BG_BLACK="\e[40m"

# 灰色 & 重置
GRAY="\e[90m";      BOLD_GRAY="\e[1;90m"
RESET="\e[0m";      D="${GRAY}"        # Dim 的简写

# ═══════════════════════════════════════════════════════════
# 日志函数（完美使用全大写助记符）
# ═══════════════════════════════════════════════════════════
debug() {
        case "${DEBUG:-0}" in
                1|true|TRUE|on|ON|yes|YES) ;;
                *) return 0 ;;
        esac
        local f="${FUNCNAME[1]:-main}" l="${BASH_LINENO[0]}"
        printf "${MAGENTA}[DEBUG] ${CYAN}[${f}:${l}] %s${RESET} ${BLACK}%s${RESET}\n" \
                "$(date '+%H:%M:%S')" "$*" >&2
}

info() {
        local f="${FUNCNAME[1]:-main}" l="${BASH_LINENO[0]}"
        printf  "${BLUE}[INFO]  ${CYAN}[${f}:${l}] %s${RESET} ${BLUE}%s${RESET}\n" \
                "$(date '+%H:%M:%S')" "$*" >&2
}

warn() {
        local f="${FUNCNAME[1]:-main}" l="${BASH_LINENO[0]}"
        printf "${BG_YELLOW}${BLACK}[WARN] ${RESET} ${CYAN}[${f}:${l}] %s${RESET} ${BG_YELLOW}${BLACK}%s${RESET}\n" \
                "$(date '+%H:%M:%S')" "$*" >&2
}

alert() {
        local f="${FUNCNAME[1]:-main}" l="${BASH_LINENO[0]}"
        printf "${BG_RED}${BOLD_BLACK}[ALERT]${RESET} ${CYAN}[${f}:${l}] %s${RESET} ${BG_RED}${BOLD_BLACK}%s${RESET}\n" \
                "$(date '+%H:%M:%S')" "$*" >&2
}

error() {
        local f="${FUNCNAME[1]:-main}" l="${BASH_LINENO[0]}"
        printf "${BG_BLACK}${BOLD_WHITE}[ERROR]${RESET} ${CYAN}[${f}:${l}] %s${RESET} ${BG_BLACK}${BOLD_WHITE}%s${RESET}${RESET}\n" \
                "$(date '+%H:%M:%S')" "$*" >&2
        exit 1
}

success() {
        local f="${FUNCNAME[1]:-main}" l="${BASH_LINENO[0]}"
        printf "${BG_GREEN}${BOLD_BLACK}[SUCC] ${RESET} ${CYAN}[${f}:${l}] %s${RESET} ${BG_GREEN}${BOLD_BLACK}%s${RESET}\n" \
                "$(date '+%H:%M:%S')" "$*" >&2
}
#        DEBUG=1 debug "debug1"
#        DEBUG=0 debug "debug2"
#        info "info"
#        warn "warn"
#        alert "alert"
#        error "error"
#        success "success"
printvar() {
        local c='\e[36m' y='\e[33m' g='\e[32m' r='\e[31m' z='\e[0m'
        for v; do
                if ! declare -p "$v" &>/dev/null; then
                        printf "${RED}[UNSET]  ${CYAN}%s${RESET} = ${RED}(undefined)${RESET}\n" "$v"
                        continue
                fi
                local val="${!v}"
                local type="$(declare -p "$v" 2>/dev/null | awk '{print $2}' | cut -d- -f2 || echo '')"
                [[ -z "$type" ]] && type="scalar"
                [[ "$type" == "a" ]] && type="array(${#val[@]})"
                [[ "$type" == "A" ]] && type="assoc(${!val[@]})"
                #[[ ${#val} -gt 80 ]] && val="${val:0:77}..."
                printf "${CYAN}%-18s${RESET} = ${YELLOW}%s${RESET} ${g}[%s]${RESET}\n" "$v" "$val" "$type"
         done
}

alias p=printvar

title() {
        # ── 内容准备 ─────────────────────────────────────
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')           # 固定 19 字符
        local text="${1:-}"                             # 传入标题（支持空）
        local padding="  "                              # 时间与标题间距

        # 计算内容总长度（时间 + 间距 + 标题）
        local content_length=$(( ${#timestamp} + ${#padding} + ${#text} ))

        # 最小内部宽度（至少容纳时间 + 间距 + 短标题）
        local min_inner=46
        local inner=$(( content_length > min_inner ? content_length : min_inner ))

        # 总宽度 = 内部宽度 + 左右边框 2
        local total=$(( inner + 2 ))

        # ── 生成横线（使用 ═） ───────────────────────────
        local line
        #‘%*s’是让printf 将接下来的第一个参数当作宽度，第二个参数是替换的字符串，剩余的用空格填充。
        #这里因为是空字符，所以全部都填充空格
        printf -v line '%*s' "$total" ''
        line=${line// /═}

        # ── 输出标题框 ───────────────────────────────────
        printf "${BOLD_BLACK}╔${line}╗${RESET}\n"
        printf "${BOLD_BLACK}║ ${BOLD_WHITE}%s${BOLD_BLACK}%s%-*s ║${RESET}\n" \
                "$timestamp" "$padding" $(( inner - ${#timestamp} - ${#padding} )) "$text"
                        printf "${BOLD_BLACK}╚${line}╝${RESET}\n"
}

redraw() {
        #清除整行
        #CSI Ps K  Erase in Line (EL), VT100.
        #       Ps = 0  ⇒  Erase to Right (default).
        #       Ps = 1  ⇒  Erase to Left.
        #       Ps = 2  ⇒  Erase All.
        printf "\033[1K\r%s" "$1"
}
# }}}

# Prepare the operating environment
# {{{
check_tools(){
        tools=( "playerctl" "conky" "awk" "curl" "mkfifo" "jq" )
        for tool in "${tools[@]}"
        do
                command -v "$tool" >/dev/null || { error "$tool is required, you may need to install it first!"; }
        done
}; check_tools

prepare_environment(){
        local runtime_dir="${APP_RUNTIME_DIR:?APP_RUNTIME_DIR must be set}"
        mkdir -p "$runtime_dir" || { error "mkdir -p $runtime_dir failed"; }
        mkdir -p "$APP_LRC_DIR" || { error "mkdir -p $APP_LRC_DIR failed"; }
        if [[ -r "$APP_CUSTOMIZATION" ]]
        then
                #read gap_x gap_y < ""
                #conky_config+="gap_x = $gap_x, gap_y = $gap_y,"
                :
        fi
}; prepare_environment

quit(){
        echo
        info "正在关闭 Conky..."
        close_conky
        exit 0
};trap quit SIGINT SIGTERM EXIT
# }}}

# Define functions that operate on pipelines
# {{{
check_pipe(){
        local pipe="${APP_PIPE_FILE:?APP_PIPE_FILE must be set}"
        [[ -e "$pipe" ]] || { mkfifo "$pipe" && return 0; error "mkfifo $pipe failed"; }
        [[ -p "$pipe" ]] || { error "$pipe isn't a pipe file"; }
        [[ -r "$pipe" && -w "$pipe" ]] || { error "Ensure $pipe is a readable and writable FIFO"; }
}; check_pipe

write_pipe(){
        echo -e "$*" >> $APP_PIPE_FILE || { warn "write pipe failed "; } 
}

clear_pipe(){
        echo -e " \n " >> $APP_PIPE_FILE || { warn "clear pipe failed "; } 
}
# }}}

# Configure and run conky in the background
# {{{

#Detect conky survival
check_conky_survival(){
        debug $CONKY_PID
        [[ $CONKY_RUNNING=="yes" ]] && { kill -0 "$CONKY_PID" 2>/dev/null || { error "conky isn't survival"; } }
}; 

launch_conky(){
        info "launching conky"
        CONKY_RUNNING="no"
        conky -q -c - << EOF &
conky.config = {
        alignment = 'top_left',
        gap_x = 40,
        gap_y = 0,
        minimum_width = 200,
        minimum_height = 10,
        own_window = true,
        own_window_class='ConkyLyricsPro',
        own_window_type = 'normal',
        own_window_transparent = true,
        own_window_argb_visual = true,
        own_window_argb_value = 0,
        own_window_hints = 'undecorated,above,sticky,skip_taskbar,skip_pager',
        double_buffer = true,
        draw_borders = true,
        draw_shades = true,
        default_shade_color = '000000',     -- 深灰阴影，柔和不刺眼
        draw_outline = true,
        default_outline_color = '000000',   -- 细黑描边，增强立体感
        default_color = 'FFFFFF',           -- 纯白主色
        color1 = '00FFFF',                  -- 青绿 → 当前已唱
        color2 = 'FF4500',                  -- 橙红 → 当前未唱
        color3 = 'FFD700',                  -- 金色 → 下一句预览
        color4 = '32CD32',
        use_xft=true,
        stippled_borders = 0,
        border_width = 0,
        update_interval = 1,
        font='Hack',
        font0='Noto Color Emoji:size=$CONKY_FONT_SIZE',
        font1='Noto Sans Mono CJK SC:size=$CONKY_FONT_SIZE',
        font2='汇文明朝体::size=$CONKY_FONT_SIZE',
        font3='汇文明朝体::size=$CONKY_FONT_SIZE',
--        lua_load='~/.conky/breath.lua',
--        lua_draw_hook_pre='breath_bg',
}
conky.text = [[
\${color4}\${font2}\${execpi 0.2 head -n 3 $APP_PIPE_FILE }
]]
EOF
        sleep 0.5
        CONKY_PID="$!"
        CONKY_RUNNING="yes"
        check_conky_survival
}; launch_conky

# 捕获退出信号，杀掉 Conky
close_conky() {
        #if command -v wmctrl >/dev/null; then
        #        pos=$(wmctrl -lG | grep "conky" | awk '{print $3" "$4}')
        #        [[ -n "$pos" ]] && echo "$pos" > "$APP_RUNTIME_DIR/position"
        #fi
        CONKY_RUNNING="no"
        local conky_pid="${CONKY_PID:?CONKY_PID must be set}"
        jobs -p | xargs -r kill >/dev/null 2>&1
        sleep 0.5
} 

adjust_fontsize_conky(){
        local delta="${1:-5}"
        (( CONKY_FONT_SIZE+=delta ))
        (( CONKY_FONT_SIZE < 10 )) && CONKY_FONT_SIZE=10
        close_conky
        launch_conky
}

# }}}

# Define functions that operate on the database
# {{{
initialize_db() {
        local db_file="${APP_DB_FILE:?APP_DB_FILE must be set}"
        {
        sqlite3 "$APP_DB_FILE" << SQL
CREATE TABLE IF NOT EXISTS lyrics (
id      INTEGER PRIMARY KEY,
track   TEXT NOT NULL,
artist  TEXT NOT NULL,
album   TEXT NOT NULL,
lyrics  TEXT NOT NULL,
fetched_at INTEGER NOT NULL,
offset  INTEGER NOT NULL default 0,
UNIQUE(track, artist, album)
);
SQL
        } || { warn "create table in DB:$APP_DB_FILE failed "; } 
};initialize_db

escape_string(){
        local string="$1"
        local string=${string//$'\n'/\\n}
        string=${string//\"/\*}
        string=${string//\'/\*}
        echo -n "$string"
}
# 返回 0=缓存命中, 1=未命中
get_lyrics_from_db() {
        local db_file="${APP_DB_FILE:?APP_DB_FILE must be set}"
        local music_track=$(escape_string "$MUSIC_TRACK")
        local music_artist=$(escape_string "$MUSIC_ARTIST")
        local music_album=$(escape_string "$MUSIC_ALBUM")
        local lyrics=$(sqlite3 "$APP_DB_FILE" << SQL
.param init
.param clear
.param set :track  '$music_track'
.param set :artist '$music_artist'
.param set :album  '$music_album'
SELECT lyrics FROM lyrics
WHERE track=:track AND artist=:artist AND album=:album
ORDER BY fetched_at DESC LIMIT 1;
SQL
        ) || { warn "select lyrics with $MUSIC_TRACK,$MUSIC_ARTIST,$MUSIC_ALBUM in DB:$APP_DB_FILE failed "; }
        [[ -z $lyrics ]] && { return 1; }
        LYRICS_DB_CONTENT="$lyrics"; 
        MUSIC_OFFSET=$(sqlite3 "$APP_DB_FILE" << SQL
.param init
.param clear
.param set :track  '$music_track'
.param set :artist '$music_artist'
.param set :album  '$music_album'
SELECT offset FROM lyrics
WHERE track=:track AND artist=:artist AND album=:album
ORDER BY fetched_at DESC LIMIT 1;
SQL
) || { warn "select offset with $MUSIC_TRACK,$MUSIC_ARTIST,$MUSIC_ALBUM in DB:$APP_DB_FILE failed "; }
        return 0
}

save_lyrics_to_db() {
        local db_file="${APP_DB_FILE:?APP_DB_FILE must be set}"
        (( ${#LYRICS_DB_CONTENT} < 10 )) && return 1
        local music_track=$(escape_string "$MUSIC_TRACK")
        local music_artist=$(escape_string "$MUSIC_ARTIST")
        local music_album=$(escape_string "$MUSIC_ALBUM")
        local music_offset=$(escape_string "$MUSIC_OFFSET")
        local lyrics_escaped=$(escape_string "$LYRICS_DB_CONTENT")
        {
        sqlite3 "$db_file" << SQL
.param set :track  '$music_track'
.param set :artist '$music_artist'
.param set :album  '$music_album'
.param set :offset "$music_offset"
.param set :lyrics "$lyrics_escaped"
INSERT OR REPLACE INTO lyrics
(track, artist, album, lyrics, fetched_at, offset)
VALUES (:track, :artist, :album, :lyrics, strftime('%s','now'),:offset);
SQL
        } || { warn "insert lyrics with $MUSIC_TRACK,$MUSIC_ARTIST,$MUSIC_ALBUM in DB:$APP_DB_FILE failed "; }
}

delete_lyrics_from_db(){
        local db_file="${APP_DB_FILE:?APP_DB_FILE must be set}"
        local music_track=$(escape_string "$MUSIC_TRACK")
        local music_artist=$(escape_string "$MUSIC_ARTIST")
        local music_album=$(escape_string "$MUSIC_ALBUM")
        #warn "DELETE FROM LYRICS WHERE ( track=$music_track and artist=$music_artist and album=$music_album );"
        {
        sqlite3 "$db_file" << SQL
.param set :track  '$music_track'
.param set :artist '$music_artist'
.param set :album  '$music_album'
DELETE FROM LYRICS WHERE ( track=:track and artist=:artist and album=:album );
SQL
        } || { warn "delete $MUSIC_TRACK,$MUSIC_ARTIST,$MUSIC_ALBUM in DB:$APP_DB_FILE failed "; }
}
# }}}

# Generate URL for fetching lyrics
# {{{
urlencode() {
        local LC_ALL=C
        local s="$1"
        local i c h
        for ((i=0; i<${#s}; i++)); do
                c="${s:i:1}"
                case "$c" in
                        [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
                        *) printf '%%%02X' "'$c" ;;
                esac
        done
}

urlbuild() {
        local base="$1"
        shift
        local params=()
        for p in "$@"; do
                params+=("$(urlencode "${p%%=*}")=$(urlencode "${p#*=}")")
        done
        printf '%s?%s\n' "$base" "$(IFS=\&; echo "${params[*]}")"
}
# }}}

# Define functions to process the music's metadata and lyrics
# {{{
print_music_meta(){
        p MUSIC_TRACK MUSIC_ALBUM MUSIC_ARTIST MUSIC_LENGTH LYRICS_DISPLAY_CONTENT
}

get_music_meta(){
        MUSIC_TRACK=$(ctrl_client metadata -f "{{title}}")   || { warn "ctrl_client meta -f {{title}} failed ";return 1; }
        MUSIC_ALBUM=$(ctrl_client metadata -f "{{album}}")   || { warn "ctrl_client meta -f {{album}} failed ";return 1; }
        MUSIC_ARTIST=$(ctrl_client metadata -f "{{artist}}") || { warn "ctrl_client meta -f {{artist}} failed ";return 1; }
        MUSIC_LENGTH=$(awk -v len="$(ctrl_client metadata -f "{{mpris:length}}")" 'BEGIN {printf "%.2f", len/1000000}') || { warn "ctrl_client meta -f {{artist}} failed ";return 1; }
        return 0
} 

cleanup_search_lyrics(){
        LYRICS_ARRAY_SYNCEDLYRICS=()
        LYRICS_DB_CONTENT=""
        LYRICS_JS_SEARCH_RESPONSE=""
        LYRICS_SEARCH_ARRAY_COUNT=0
        LYRICS_SEARCH_ARRAY_SYNCEDLYRICS=()
        MUSIC_OFFSET="0"
}

search_lyrics(){
        local save_to_db=${1:-1}
        write_pipe "<<  $MUSIC_TRACK  >>\n\${color0}歌词搜索中..."
        echo
        info "[网络搜索] $MUSIC_TRACK $MUSIC_ALBUM $MUSIC_ARTIST"
        local lyric_url=$(urlbuild "https://lrclib.net/api/search" "q=$MUSIC_TRACK" "track_name=$MUSIC_TRACK" "album_name=$MUSIC_ALBUM" "artist_name=$MUSIC_ARTIST")
        DEBUG=1 debug "$lyric_url"
        local lyric_search_cmd="$APP_CURL_COMMAND '$lyric_url'" 
        LYRICS_JS_SEARCH_RESPONSE=$(eval $lyric_search_cmd) || { warn "Fetch lyrics with \"$lyric_search_cmd\" failed"; return 1; }
        [[ -n $LYRICS_JS_SEARCH_RESPONSE ]] && {
                local IFS=$'\n';
                LYRICS_SEARCH_ARRAY_SYNCEDLYRICS=($(jq ' [ .[] | select(.syncedLyrics != null and .syncedLyrics !="" and (.syncedLyrics | test("^\\s*$") | not)) | {l: .syncedLyrics, d: ((.duration - '"$MUSIC_LENGTH"') | fabs)} ] | sort_by(.d) | .[].l ' <<< "$LYRICS_JS_SEARCH_RESPONSE")) || { warn "Parse lyrics failed"; return 1; }
                LYRICS_SEARCH_ARRAY_COUNT="${#LYRICS_SEARCH_ARRAY_SYNCEDLYRICS[@]}"
                LYRICS_ARRAY_SYNCEDLYRICS+=("${LYRICS_SEARCH_ARRAY_SYNCEDLYRICS[@]}")
                LYRICS_ARRAY_INDEX=0
                parse_lyrics "$save_to_db"
        }
        return $?
}

cleanup_last_lyrics(){
        cleanup_search_lyrics
        LYRICS_ARRAY_INDEX=0
        LYRICS_ARRAY_COUNT=0
        LYRICS_DISPLAY_CONTENT=""
}

fetch_lyrics(){
        write_pipe "<<  $MUSIC_TRACK  >>\n\${color0}歌词载入中..."
        cleanup_last_lyrics
        local save_to_db=1
        local success=0
        get_lyrics_from_db
        if [[ $? == 0 ]]
        then
                echo
                info "[缓存命中] $MUSIC_TRACK $MUSIC_ALBUM $MUSIC_ARTIST";
                LYRICS_ARRAY_SYNCEDLYRICS=("$LYRICS_DB_CONTENT")
                save_to_db=0
                success=1
        else
                echo
                info "[网络获取] $MUSIC_TRACK $MUSIC_ALBUM $MUSIC_ARTIST"
                local lyric_url=$(urlbuild "https://lrclib.net/api/get" "track_name=$MUSIC_TRACK" "album_name=$MUSIC_ALBUM" "artist_name=$MUSIC_ARTIST" duration="${MUSIC_LENGTH%%.*}")
                DEBUG=1 debug "$lyric_url"
                local lyric_fetch_cmd="$APP_CURL_COMMAND '$lyric_url'" 
                LYRICS_JS_RESPONSE=$(eval $lyric_fetch_cmd) || { warn "Fetch lyrics with \"$lyric_fetch_cmd\" failed"; LYRICS_JS_RESPONSE=""; }
                [[ -n $LYRICS_JS_RESPONSE ]] && {
                        local IFS=$'\n';
                        LYRICS_ARRAY_SYNCEDLYRICS=($(jq '.|select(.syncedLyrics != null and .syncedLyrics !="" and (.syncedLyrics | test("^\\s*$") | not)).syncedLyrics' <<< "$LYRICS_JS_RESPONSE")) || { warn "Parse lyrics failed"; return 1; }
                        LYRICS_ARRAY_COUNT="${#LYRICS_ARRAY_SYNCEDLYRICS[@]}"
                        (( $LYRICS_ARRAY_COUNT >0 )) && success=1
                }

        fi

        if (( $success ==1 ))
        then
                parse_lyrics "$save_to_db"
        else
                search_lyrics "$save_to_db"
        fi
        return $?
}

dump_lyrics(){
        echo -n "$LYRICS_DB_CONTENT" > "$APP_LRC_DIR/$MUSIC_TRACK.lrc"
        echo
        info "Dump LRC: $(printf %q "$APP_LRC_DIR/$MUSIC_TRACK.lrc")"
}

upload_lyrics(){
        local lyrics_upload_lrc=("$(cat "$APP_LRC_DIR/$MUSIC_TRACK.lrc")")
        if [[ -n $lyrics_upload_lrc ]]
        then
                LYRICS_ARRAY_SYNCEDLYRICS=("$lyrics_upload_lrc")
                parse_lyrics 
        else
                warn "no $APP_LRC_DIR/$MUSIC_TRACK.lrc or the $APP_LRC_DIR/$MUSIC_TRACK.lrc is empty"
        fi
}

parse_lyrics(){
        local save_to_db=${1:-1}
        LYRICS_ARRAY_COUNT="${#LYRICS_ARRAY_SYNCEDLYRICS[@]}"
        (( $LYRICS_ARRAY_COUNT > 0 )) && { 
                LYRICS_DB_CONTENT=$(echo -e "${LYRICS_ARRAY_SYNCEDLYRICS[$LYRICS_ARRAY_INDEX]}")
                #英文歌曲不能把空格去掉
                LYRICS_DISPLAY_CONTENT=$(awk -F'[:.\\[\\]]' 'NF>=2{lyrics_timestemp=($2*60+$3)"."$4;print lyrics_timestemp,$5}'<<<"$LYRICS_DB_CONTENT")

                [[ $save_to_db == 1 ]] && save_lyrics_to_db
                #https://www.gnu.org/software/freefont/ranges/symbols.html
                #ⒶⒷⒸⒹⒺⒻⒼⒽⒾⒿⓀⓁⓂⓃⓄⓅⓆⓇⓈⓉⓊⓋⓌⓍⓎⓏ
                #ⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩ
                [[ -n $LYRICS_DISPLAY_CONTENT ]] && LYRICS_DISPLAY_CONTENT="0.0 ⓒⓞⓝⓚⓨ ⓛⓨⓡⓘⓒⓢ ⓟⓡⓞ"$'\n'"$LYRICS_DISPLAY_CONTENT"
        } 
        print_music_meta
        return 0
}

navigate_lyrics(){
        local direction="${1:-1}"
        #如果搜索歌词数组为0，就去search一下
        if (( LYRICS_SEARCH_ARRAY_COUNT == 0 ))
        then
                search_lyrics 0
        #有歌词并且大于一组，才去切换。
        elif (( LYRICS_ARRAY_COUNT > 1 ))
        then
                (( LYRICS_ARRAY_INDEX = (LYRICS_ARRAY_INDEX + direction + LYRICS_ARRAY_COUNT) % LYRICS_ARRAY_COUNT ));
                parse_lyrics 0;
                # 新增：切换提示（仅显示 1 秒）
                #write_pipe "\${color3}已切换到歌词版本 $((LYRICS_ARRAY_INDEX + 1))/${LYRICS_ARRAY_COUNT}"
                #sleep 1
                #clear_pipe
        fi
}
# }}}

#走马灯效果（marquee）
# {{{
_marquee_count=0
scrolling_marquee(){
        local prefix="${1:-}"
        local max="${2:-10}"
        local step="${3:-1}"
        local symbol="${4:-❤}"
        #‘%*s’是让printf 将接下来的第一个参数当作宽度，第二个参数是替换的字符串，剩余的用空格填充。
        #这里因为是空字符，所以全部都填充空格
        printf -v marquee "%*s" "$_marquee_count" ''
        marquee="${marquee// /$symbol}"
        (( _marquee_count = (_marquee_count+step)%max ))
        write_pipe "$prefix$marquee"
}
reset_marquee(){
        _marquee_count=0
}
# }}}

#main loop and handle keys 
# {{{
handle_keys() {
        ret=0
        local timeout="0.05"   # 检测间隔（秒），可根据需要调整
        # 尝试读取 1 个字符，最多等 $timeout 秒
        if read -t $timeout -n 1 key 2>/dev/null; then
                case "$key" in
                        q) quit ;;
                        -) navigate_lyrics -1;      ret=1;;
                        =|+) navigate_lyrics 1;     ret=1;;
                        a) adjust_fontsize_conky 10; ret=2;;
                        s) adjust_fontsize_conky -10;ret=2;;
                        S) save_lyrics_to_db;;
                        D) delete_lyrics_from_db;;
                        n) PLAY_NEW_MUSIC=1;;
                        d) dump_lyrics;;
                        u) upload_lyrics;;
                        !) MUSIC_OFFSET=$(awk -v a="$MUSIC_OFFSET" -v b="-10" 'BEGIN {printf "%.2f", a+b}');;
                        1) MUSIC_OFFSET=$(awk -v a="$MUSIC_OFFSET" -v b="10" 'BEGIN {printf "%.2f", a+b}');;
                        @) MUSIC_OFFSET=$(awk -v a="$MUSIC_OFFSET" -v b="-1" 'BEGIN {printf "%.2f", a+b}');;
                        2) MUSIC_OFFSET=$(awk -v a="$MUSIC_OFFSET" -v b="1" 'BEGIN {printf "%.2f", a+b}');;
                        \#) MUSIC_OFFSET=$(awk -v a="$MUSIC_OFFSET" -v b="-0.1" 'BEGIN {printf "%.2f", a+b}');;
                        3) MUSIC_OFFSET=$(awk -v a="$MUSIC_OFFSET" -v b="0.1" 'BEGIN {printf "%.2f", a+b}');;
                        *) ;;
                esac
        fi
        return "$ret"
}

main(){
        local curr_music_pos=0
        local last_music_pos=0
        local curr_music_track=""
        local last_music_track=""
        local curr_music_artist=""
        local lyrics_skip_lines=0
        local curr_skip_lines=0
        while true
        do
                last_music_pos=0
                lyrics_skip_lines=0
                curr_skip_lines=0
                PLAY_NEW_MUSIC=0
                reset_marquee
                get_music_meta || { warn "get_music_meta failed "; sleep 3; continue; } 
                fetch_lyrics || { warn "fetch_lyrics failed "; } 
                while true
                do
                        #处理键盘按键,
                        handle_keys
                        case $? in
                                1) lyrics_skip_lines=0; ;;
                                2) print_music_meta ;;
                        esac

                        read -r curr_music_pos curr_music_track <<<$(ctrl_client metadata -f "{{position}} {{title}}") || { warn "ctrl_client metadata -f \"{{position}} {{title}}\" "; sleep 1; continue; }
                        curr_music_artist=$(ctrl_client metadata -f "{{artist}}") || { warn "ctrl_client meta -f {{artist}} failed ";return 1; }
                        curr_music_pos=$(awk -v pos="$curr_music_pos" -v offset="$MUSIC_OFFSET" 'BEGIN {printf "%.2f", pos/1000000+offset}')

                        #处理自动或者手动切换歌曲
                        [[ $curr_music_track != $MUSIC_TRACK || $curr_music_artist != $MUSIC_ARTIST ]] && { PLAY_NEW_MUSIC=1; } 
                        [[ $PLAY_NEW_MUSIC == 1 ]] && break;
                        #处理播放器调整播放进度
                        (( $(bc <<< "$curr_music_pos < $last_music_pos") ))  && { clear_pipe; lyrics_skip_lines=0; }

                        last_music_pos=$curr_music_pos
                        redraw "\
position:$curr_music_pos \
skip_lines:$lyrics_skip_lines \
curr_skip_lines:$curr_skip_lines \
conky fontsize:$CONKY_FONT_SIZE \
conky_pid:$CONKY_PID \
index:$LYRICS_ARRAY_INDEX \
count:$LYRICS_ARRAY_COUNT \
search count:$LYRICS_SEARCH_ARRAY_COUNT \
offset:$MUSIC_OFFSET \
"
                        if [[ -n $LYRICS_DISPLAY_CONTENT ]]
                        then
                                local lyrics_show=$(awk -v title="$MUSIC_TRACK" -v position=$curr_music_pos -v skip=$lyrics_skip_lines 'NR>skip {
                                                pos=position
                                                if($1>=pos+1){
                                                        if( length(last) >0 ){
                                                                #print "1:"$1
                                                                #print "pos:"pos
                                                                n=length(last)
                                                                total_length=$1-last_timestemp
                                                                if( 0 == total_length ){
                                                                        total_length=1
                                                                }
                                                                insert_pos = int(n*(pos-last_timestemp+2)/($1-last_timestemp)) 
                                                                if(NR%2){
                                                                        #print "$""{color" NR%4+1 "}""<<  "title"  >>"
                                                                        print "<<  "title"  >>"
                                                                        $1=""
                                                                        print "$""{color3}""$""{font3}"$0
                                                                        print "$""{color1}" substr(last,1,insert_pos) "$""{color2}" substr(last,insert_pos+1)
                                                                }else{
                                                                        #print "$""{color" NR%4+1 "}""<<  "title"  >>"
                                                                        print "<<  "title"  >>"
                                                                        print "$""{color1}" substr(last,1,insert_pos) "$""{color2}" substr(last,insert_pos+1)
                                                                        $1=""
                                                                        print "$""{color3}""$""{font3}"$0
                                                                }
                                                                print remove_lines
                                                                exit
                                                        }
                                                }else{
                                                        remove_lines++
                                                        last_timestemp=$1
                                                        $1=""
                                                        last=$0
                                                }
                                        }' <<< "$LYRICS_DISPLAY_CONTENT") 
                                if [[ -n $lyrics_show ]]
                                then
                                        #如果有歌词需要显示
                                        write_pipe "$(head -n 3 <<< "$lyrics_show")"
                                        #跳过歌词主要是为了考虑节省性能，因为已经显示过的歌词没有用了。但不能删，因为有可能会调整播放进度（拖动进度条）
                                        curr_skip_lines=$(tail -n 1 <<<"$lyrics_show")
                                        (( curr_skip_lines >= 1 )) && { lyrics_skip_lines=$((lyrics_skip_lines+curr_skip_lines-1)); }
                                        reset_marquee
                                else
                                        #歌词不存在或者歌词中的空白行
                                        scrolling_marquee "<<  $MUSIC_TRACK  >>\n\${font0}"
                                fi
                        else
                                #3是因为只有3种颜色
                                scrolling_marquee "$(printf "<<  $MUSIC_TRACK  >>\n\${color%d}暂无歌词\n\${font0}" $((_marquee_count%3+1)))"
                        fi
                        sleep 0.2
                done
                clear_pipe
        done
}; main
# }}}
