#include <ctype.h>
#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

int grid[9] = {0};
int player = -1;
const int win_conds[8][3] = {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}, {0, 3, 6},
                             {1, 4, 7}, {2, 5, 8}, {0, 4, 8}, {2, 4, 6}};

void clearscreen() { system("clear"); }

void drawboard() {
  printf("TIC-TAC-TOE\n-------\n");
  for (int i = 0; i < 3; i++) {
    printf("|");
    for (int j = 0; j < 3; j++) {
      switch (grid[i * 3 + j]) {
      case 0:
        printf(" ");
        break;
      case 1:
        printf("X");
        break;
      case 2:
        printf("O");
        break;
      }
      printf("|");
    }
    printf("\n-------\n");
  }
}

void choose_character() {
  printf("Please select X or O: ");
  char x;
  scanf(" %c", &x);
  x = tolower(x);

  while (x != 'x' && x != 'o') {
    clearscreen();
    drawboard();
    printf("Invalid choice. Please enter only X or O: ");
    scanf(" %c", &x);
    x = tolower(x);
  }

  clearscreen();
  drawboard();

  player = (x == 'x') ? 0 : 1;
}

bool valid_cell(int cell) { return cell >= 0 && cell < 9 && grid[cell] == 0; }

int game_status() {
  for (int i = 0; i < 8; i++) {
    int a = win_conds[i][0], b = win_conds[i][1], c = win_conds[i][2];
    if (grid[a] != 0 && grid[a] == grid[b] && grid[b] == grid[c])
      return grid[a];
  }

  for (int i = 0; i < 9; i++) {
    if (grid[i] == 0)
      return 0;
  }

  return 3;
}

int ask_player() {
  int x, y, cell;
  printf("Enter row (1-3) and column (1-3): ");
  scanf("%d %d", &x, &y);

  cell = (y - 1) * 3 + (x - 1);

  while (x < 1 || x > 3 || y < 1 || y > 3 || !valid_cell(cell)) {
    clearscreen();
    drawboard();
    printf("Invalid move! Enter row (1-3) and column (1-3): ");
    scanf("%d %d", &x, &y);
    cell = (y - 1) * 3 + (x - 1);
  }

  return cell;
}

void player_play() {
  int cell = ask_player();
  grid[cell] = player + 1;
}

int backtrack(bool is_ai_turn) {
  int status = game_status();

  if (status == 2 - player)
    return +1;
  if (status == player + 1)
    return -1;
  if (status == 3)
    return 0;

  int best_score = is_ai_turn ? INT_MIN : INT_MAX; // Maximize on AI turn, Minimize on our turn.

  for (int i = 0; i < 9; i++) {
    if (valid_cell(i)) {
      grid[i] = is_ai_turn ? (2 - player) : (player + 1);
      int score = backtrack(!is_ai_turn);
      grid[i] = 0;

      if (is_ai_turn) {
        best_score = (score > best_score) ? score : best_score; // Max
      } else {
        best_score = (score < best_score) ? score : best_score; // Min
      }
    }
  }

  return best_score;
}

void computer_play() {
  int best_move = -1;
  int best_score = INT_MIN;

  for (int i = 0; i < 9; i++) {
    if (valid_cell(i)) {
      grid[i] = 2 - player;
      int score = backtrack(false);
      grid[i] = 0;

      if (score > best_score) {
        best_score = score;
        best_move = i;
      }
    }
  }

  if (best_move != -1) {
    grid[best_move] = 2 - player;
  }
}

void play() {
  while (game_status() == 0) {
    if (player == 0) {
      clearscreen();
      drawboard();
      player_play();
      if (game_status() != 0)
        break;
      computer_play();
    } else {
      computer_play();
      clearscreen();
      drawboard();
      if (game_status() != 0)
        break;
      player_play();
    }
  }

  clearscreen();
  drawboard();

  switch (game_status()) {
  case 1:
  case 2:
    printf("%s wins!\n", (game_status() == player + 1) ? "Player" : "Computer");
    break;
  case 3:
    printf("It's a tie!\n");
    break;
  }
}

int main() {
  drawboard();
  choose_character();
  play();
  return 0;
}
