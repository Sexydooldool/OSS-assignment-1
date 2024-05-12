#!/bin/bash

#학번 이름

print_student_info() {
    echo "*******************OSS1 - Project1*******************"
    echo "* StudentID : 12214199 *"
    echo "* Name : Hae In Cho *"
    echo "*****************************************************"
}

#메뉴 출력 함수

print_menu() {
    echo "1. Get Heung-Min Son's Current Club, Appearances, Goals, Assists"
    echo "2. Get team data to enter a league position"
    echo "3. Get Top-3 Attendance matches"
    echo "4. Get team's league position and top scorer"
    echo "5. Get modified format of date_GMT"
    echo "6. Get data of winning team by largest difference on home stadium"
    echo "7. Exit"
    echo -n "Enter your choice: "
}

#손흥민 선수의 정보 가져오기

get_son_data() {
    read -p "Do you want to get Heung-Min Son's data? (y/n): " choice
    case $choice in
        y|Y) grep "Heung-Min Son" players.csv | awk -F ',' '{printf("Team:%s, Appearance:%s, Goal:%s, Assist:%s\n", $4, $6, $7, $8)}' ;;
        n|N) echo "Returning to the main menu." ;;
        *) echo "Invalid option. Returning to the main menu." ;;
    esac
}


#리그 포지션을 입력받고 그에 맞는 팀의 정보 가져오기

print_team_info_by_position() {
    # 사용자로부터 리그 포지션 입력 받기
    read -p "Enter a league position (1-20): " position

    # 입력한 포지션이 유효한지 확인
    if ! [[ "$position" =~ ^[1-9]$|^1[0-9]$|^20$ ]]; then
        echo "Invalid league position. Please enter a number between 1 and 20."
        return
    fi

    # teams.csv 파일에서 해당 포지션을 가진 팀의 정보 출력
    while IFS=',' read -r common_name wins draws losses points_per_game league_position cards_total shots fouls
    do
        # 입력한 포지션과 일치하는 팀인지 확인
        if [ "$league_position" -eq "$position" ]; then
            # 승률 계산
            total_matches=$(( wins + draws + losses ))
            if [ "$total_matches" -gt 0 ]; then
                win_rate=$(( (wins * 100) / total_matches ))
            else
                win_rate=0
            fi

            # 팀 정보 출력
            echo "팀 이름: $common_name"
            echo "승: $wins, 무: $draws, 패: $losses"
            echo "승률: $win_rate%"
            return
        fi
    done < <(tail -n +2 teams.csv) # 헤더를 제외하고 팀 데이터를 읽어옵니다.

    echo "No team found with the league position $position."
}


# 관중이 많은 탑 3 경기 출력하기

print_top_3_attendance() {
    echo "Do you want to know Top-3 attendance data? (y/n)"
    read choice
    case $choice in
        y|Y)

            echo "Top-3 Attendance Matches:"
            echo "-------------------------"
            sort -t ',' -k 2 -nr matches.csv | head -n 3 | awk -F ',' '{print "Date:", $1; print "Attendance:", $2; print "Home Team:", $3; print "Away Team:", $4; print "Stadium:", $7; print "-------------------------"}'
            ;;
        n|N) echo "Returning to the main menu." ;;
        *) echo "Invalid option. Returning to the main menu." ;;
    esac
}

print_team_position_and_top_scorer() {
    # 팀 순위와 최다 득점자를 출력하는 함수
    print_team_info() {
        # teams.csv 파일에서 한 줄씩 읽어들이기
        # 첫 번째 줄은 설명이므로 무시합니다.
        IFS=',' read -r -a headers < teams.csv # 헤더를 읽어들입니다.
        while IFS=',' read -r common_name wins draws losses points_per_game league_position cards_total shots fouls
        do
            # 팀 이름을 변수에 저장
            team_name="$common_name"

            # 팀 소속 선수들의 골 데이터를 가져와 최다 득점자 찾기
            top_scorer=""
            max_goals=0
            while IFS=',' read -r full_name age position current_club nationality appearances_overall goals_overall assists_overall
            do
                if [ "$current_club" == "$team_name" ] && [ "$goals_overall" -gt "$max_goals" ]; then
                    top_scorer="$full_name"
                    max_goals="$goals_overall"
                fi
            done < players.csv

            # 팀 리그 순위와 최다 득점자 출력
            echo "팀 이름: $team_name"
            echo "리그 순위: $league_position"
            echo "최다 득점자: $top_scorer ($max_goals골)"
            echo "-----------------------------"
        done < <(tail -n +2 teams.csv | sort -t ',' -k 6 -n) # 헤더를 제외하고 팀 순위를 기준으로 오름차순 정렬합니다.
    }

    # 사용자 입력 받기
    read -p "Do you want to get each team's ranking and the highest-scoring player? (y/n) : " choice
    case $choice in
        y|Y) print_team_info ;;
        n|N) echo "Exiting." ;;
        *) echo "Invalid option. Exiting." ;;
    esac
}


get_winning_team_by_difference() {
    # teams.csv 파일에서 팀 데이터를 읽어옵니다.
    IFS=',' read -r -a headers < teams.csv # 헤더를 읽어들입니다.
    while IFS=',' read -r common_name wins draws losses points_per_game league_position cards_total shots fouls
    do
        # 팀 이름과 해당 팀의 승리 횟수를 연관 배열에 저장합니다.
        team_wins["$common_name"]=$wins

    done < <(tail -n +2 teams.csv) # 헤더를 제외하고 팀 데이터를 읽어옵니다.

    # matches.csv 파일에서 홈 경기 중 승리한 팀의 데이터를 찾습니다.
    winning_team=""
    largest_goal_difference=0
    while IFS=',' read -r date_GMT attendance home_team_name away_team_name home_team_goal_count away_team_goal_count stadium_name
    do
        if [ "$home_team_goal_count" -gt "$away_team_goal_count" ]; then
            goal_difference=$(( home_team_goal_count - away_team_goal_count ))
            if [ "$goal_difference" -gt "$largest_goal_difference" ]; then
                largest_goal_difference="$goal_difference"
                winning_team="$home_team_name"
                winning_team_goals="$home_team_goal_count"
                losing_team="$away_team_name"
                losing_team_goals="$away_team_goal_count"
                match_date="$date_GMT"
                match_stadium="$stadium_name"
            fi
        fi
    done < <(tail -n +2 matches.csv) # 헤더를 제외하고 경기 데이터를 읽어옵니다.

    # 가장 큰 골 차이를 기록한 홈 팀의 데이터를 출력합니다.
    if [ -n "$winning_team" ]; then
        echo "가장 큰 골 차이로 이긴 홈 팀:"
        echo "날짜: $match_date"
        echo "경기장: $match_stadium"
        echo "홈 팀: $winning_team ($winning_team_goals골)"
        echo "원정 팀: $losing_team ($losing_team_goals골)"
    else
        echo "홈 경기 중 가장 큰 골 차이를 기록한 승리 팀을 찾을 수 없습니다."
    fi
}

modify_date_format() {
    # 파일 경로
    file="matches.csv"

    # 파일을 변경할 지 물어보기
    read -p "파일을 변경하시겠습니까? (y/n): " choice
    if [ "$choice" != "y" ]; then
        echo "파일 변경이 취소되었습니다."
        return
    fi

    # 파일에서 각 줄을 반복하면서 날짜 형식 변경 후 새로운 파일에 저장
    while IFS= read -r line; do
        # 첫 번째 줄일 경우 그대로 formatted 파일에 추가
        if [ -z "$header" ]; then
            header="$line"
            echo "$header" > formatted_matches.csv
        else
            # 날짜 부분을 추출하여 형식 변경 후 새로운 파일에 추가
            new_date=$(date -d "$(echo "$line" | awk -F ',' '{print $1}' | sed -E 's/^([^,]+)- ([0-9]{1,2}):([0-9]{2})(am|pm)/\1 \2:\3 \4/')" +'%Y/%m/%d %l:%M%p')
            # 나머지 부분은 그대로 유지하면서 새로운 파일에 추가
            rest_of_line=$(echo "$line" | cut -d ',' -f2-)
            echo "$new_date,$rest_of_line" >> formatted_matches.csv
        fi
    done < "$file"

    mv formatted_matches.csv matches.csv

    # 파일에서 각 줄을 반복하면서 2~11번째 줄의 첫 번째 칸만 출력
    count=0
    while IFS= read -r line; do
        count=$((count+1))
        if [ $count -ge 2 ] && [ $count -le 11 ]; then
            first_column=$(echo "$line" | cut -d ',' -f1)
            echo "$first_column"
        fi
    done < "$file"
}


get_winning_team_by_difference() {
    # 팀 목록 출력 (첫 번째 줄 무시)
    echo "팀 목록:"
    i=0  # 인덱스 초기화
    while IFS=',' read -r common_name wins draws losses points_per_game league_position cards_total shots fouls
    do
        if [ $i -ne 0 ]; then  # 첫 번째 줄 무시
            echo "$((i)) $common_name"
            team_list[$i]="$common_name"
        fi
        ((i++))
    done < teams.csv

    # 사용자로부터 팀 번호 입력받기
    read -p "팀 번호를 선택하세요 (1-20): " team_number

    # 선택된 팀 이름 가져오기
    selected_team="${team_list[$team_number]}"

    # 선택된 팀의 홈 경기 중 최대 점수차로 이긴 경기 찾기
    max_diff=0
    max_diff_games=()
    while IFS=',' read -r date attendance home_team away_team home_score away_score stadium
    do
        if [ "$home_team" == "$selected_team" ] && [ $home_score -gt $away_score ]; then
            diff=$((home_score - away_score))
            if [ $diff -gt $max_diff ]; then
                max_diff=$diff
                max_diff_games=("$date, $home_team, $away_team, $home_score, $away_score, $stadium")
            elif [ $diff -eq $max_diff ]; then
                max_diff_games+=("$date, $home_team, $away_team, $home_score, $away_score, $stadium")
            fi
        fi
    done < matches.csv

    # 최대 점수차로 이긴 경기 출력
    if [ ${#max_diff_games[@]} -eq 0 ]; then
        echo "해당 팀의 홈 경기 중 최대 점수차로 이긴 경기가 없습니다."
    else
        echo "최대 점수차 $max_diff로 이긴 경기 정보:"
        for game in "${max_diff_games[@]}"
        do
            IFS=',' read -r date home_team away_team home_score away_score stadium <<< "$game"
            echo "$date"
            echo "$home_team vs $away_team / $home_score - $away_score"
        done
    fi
}

# Main program
while true; do
    
    print_student_info
    print_menu
    read choice
    case $choice in
        1) get_son_data ;;
        2) print_team_info_by_position ;;
        3) print_top_3_attendance ;;
        4) print_team_position_and_top_scorer ;;
        5) modify_date_format ;;
        6) get_winning_team_by_difference ;;
        7) echo "bye"; exit ;;
        *) echo "Invalid option. Please select again." ;;
    esac
    echo
done

