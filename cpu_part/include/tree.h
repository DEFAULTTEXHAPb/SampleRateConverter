#ifndef _TREE_H_
#define _TREE_H_

//#include <stdlib.h>
#include <inttypes.h>
#include <stdbool.h>

typedef struct tree {
    TNode * root;
    int size;
} Tree;

typedef struct treeNode {
    uint16_t            count_son;
    uint16_t            data;
    struct treeNode **  child;
} TNode;

/**
 * @brief Initilize a tree structure
 * 
 * @param ptree Tree structure pointer, that contain tree root pointer
 */
void InitializeTree(Tree * ptree);

/**
 * @brief Function that returns if tree is empty or not
 * 
 * @param ptree Tree structure pointer
 * @return true if tree is empty
 * @return false if tree isn't empty
 */
bool TreeIsEmpty(const Tree * ptree);

/**
 * @brief Function that returns if tree is full or not
 * 
 * @param ptree Tree structure pointer
 * @return true if tree is full
 * @return false if tree isn't full
 */
bool TreeIsFull(const Tree * ptree);

/**
 * @brief Returns number of tree nodes of tree structure
 * 
 * @param ptree tree structure pointer
 * @return int 
 */
int TreeItemCount(const Tree * ptree);

/**
 * @brief 
 * 
 * @param parent 
 * @param child 
 */
void AddBrunch(const TNode * parent, const TNode ** child);

uint16_t PrintSequence(const Tree * ptree);

#endif