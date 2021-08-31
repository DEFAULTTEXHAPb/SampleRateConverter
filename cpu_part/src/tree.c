#include <stdio.h>
#include <stdlib.h>
#include "../include/tree.h"

static void PrintNode(const TNode * node);
static void LinkNode(const TNode * parent, const TNode * child, const uint16_t child_num);

TNode * CreateNode(const uint16_t count_son, const uint16_t val)
{
    TNode * new_node;
    new_node->count_son = count_son;
    new_node->val = val;
    if (count_son > 0)
        new_node->child = (TNode *) malloc(count_son*sizeof(TNode));
    else
        new_node->child = NULL;
    return new_node;
}

void InitializeTree(Tree * ptree)
{
    ptree->root = NULL;
    ptree->size = 0;
}

void PrintSequence(const Tree * ptree)
{
    PrintNode(ptree->root);
}

static void PrintNode(const TNode * node)
{
    printf("%d\n", node->val);
    if (node->count_son != 0)
        for (size_t i = 0; i < node->count_son; i++)
            PrintNode(node->child[i]);
}

void LinkNodes(const TNode * parent, const TNode ** child)
{
    for (size_t i = 0; i < parent->count_son; i++)
    {
        LinkNode(parent, child[i], i);
    } 
}

static void LinkNode(const TNode * parent, const TNode * child, const uint16_t child_num)
{
    parent->child[child_num] = child;
}