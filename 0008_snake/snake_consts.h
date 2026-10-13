/* Constantes partagées entre le C et l'assembleur (ce fichier ne contient
 * que des #define, il peut être inclus depuis un .S). */
#ifndef SNAKE_CONSTS_H
#define SNAKE_CONSTS_H

#define W        30                 /* grille de W x H cases de 2 x 1 cellules */
#define W2       60
#define H        20
#define ORIGIN_Y 1
#define MAX_LEN  (W * H)
#define TICK0_MS 150                /* durée d'un pas au départ */
#define TICK_MIN 60

#endif
