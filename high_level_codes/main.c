#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define GRID_SIZE 3

char grid[GRID_SIZE][GRID_SIZE];

void populate() {
	for (int i = 0; i < GRID_SIZE; i++) {
		for (int j = 0; j < GRID_SIZE; j++) {
			grid[i][j] = ' ';
		}
	}
}

void print_grid() {
	system("clear");

	for (int i = 0; i < GRID_SIZE; i++) {
		for (int j = 0; j < GRID_SIZE; j++) {
			printf("%c ", grid[i][j]);
		}

		printf("\n");
	}
}

void computer_move() {

}

bool is_valid(int x, int y) {
	if (x < 0 || x >= GRID_SIZE || y < 0 || y >= GRID_SIZE)
		return false;

	if (grid[y][x] != ' ')
		return false;

	return true;
}

void ask_where_to_place(int player) {
	int x, y;

	do {
		printf("Please tell me where do you want to place your piece: ");

		scanf("%d %d", &x, &y);
		x--, y--;
	} while (is_valid(x, y));

	if (player) {
		grid[x][y] = 'O';
	} else {
		grid[x][y] = 'X';
	}
}

int print_menu() {
	printf("Welcome to this Tic-Toc-Toe game.\n");
	char choice;

	do {
		printf("X or O? ");
		scanf(" %c", &choice);
	} while (tolower(choice) != 'x' && tolower(choice) != 'o');

	return tolower(choice) == 'x' ? 0 : 1;
}

int main(void) {
	int player = print_menu();

	do {
		if (player == 1) {
			computer_move();
		}

		print_grid();
		printf("\n\n\n");

		ask_where_to_place(player);

		if (player == 0) {
			computer_move();
		}
	} while (true);

	return 0;
}
