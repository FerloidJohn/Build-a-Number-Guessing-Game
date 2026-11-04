#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME
ESCAPED_USERNAME=${USERNAME//\'/\'\'}

USER_DATA=$($PSQL "SELECT user_id, username FROM users WHERE username='$ESCAPED_USERNAME'")

if [[ -n $USER_DATA ]]; then
  IFS='|' read -r USER_ID DB_USERNAME <<< "$USER_DATA"
  GAME_STATS=$($PSQL "SELECT COUNT(*), COALESCE(MIN(number_of_guesses), 0) FROM games WHERE user_id=$USER_ID")
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$GAME_STATS"
  echo "Welcome back, $DB_USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  echo "Welcome, $USERNAME! It looks like this is your first time here."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
while read -r GUESS; do
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  if [[ ! $GUESS =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  elif [[ $GUESS == -* ]]; then
    echo "It's higher than that, guess again:"
  else
    NORMALIZED_GUESS=${GUESS#+}
    while [[ ${#NORMALIZED_GUESS} -gt 1 && $NORMALIZED_GUESS == 0* ]]; do
      NORMALIZED_GUESS=${NORMALIZED_GUESS#0}
    done

    if (( ${#NORMALIZED_GUESS} > 4 )); then
      echo "It's lower than that, guess again:"
    elif (( NORMALIZED_GUESS == SECRET_NUMBER )); then
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      if [[ -z $USER_ID ]]; then
        $PSQL "INSERT INTO users (username) VALUES ('$ESCAPED_USERNAME')" > /dev/null
        USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$ESCAPED_USERNAME'")
      fi
      $PSQL "INSERT INTO games (user_id, number_of_guesses) VALUES ($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null
      break
    elif (( NORMALIZED_GUESS > SECRET_NUMBER )); then
      echo "It's lower than that, guess again:"
    else
      echo "It's higher than that, guess again:"
    fi
  fi
done