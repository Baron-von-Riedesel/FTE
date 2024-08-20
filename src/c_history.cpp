/*    c_history.cpp
 *
 *    Copyright (c) 1994-1996, Marko Macek
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include "fte.h"

#ifdef CONFIG_HISTORY

#define HISTORY_VER "FTE History 1\n"

char HistoryFileName[256] = "";

static FPosHistory **FPHistory = 0;
static int FPHistoryCount = 0;

static InputHistory inputHistory = { 0, 0, 0 };

void ClearHistory() { /*FOLD00*/

    // free filenames from all entries
    while(FPHistoryCount--)
    {
        free(FPHistory[FPHistoryCount]->FileName);
        free(FPHistory[FPHistoryCount]);
    }

    // free history list
    free(FPHistory);

    // free input history
    {
        while(inputHistory.Count--)
        {
            free(inputHistory.Line[inputHistory.Count]);
        }
        free(inputHistory.Line);
        free(inputHistory.Id);
    }
}

int SaveHistory(char *FileName) { /*FOLD00*/
    FILE *fp;
    
    fp = fopen(FileName, "w");
    if (fp == 0)
        return 0;
    setvbuf(fp, FileBuffer, _IOFBF, sizeof(FileBuffer));
    fprintf(fp, HISTORY_VER);
    if (FPHistory) { // file position history
        int i,j;
        for (i = 0; i < FPHistoryCount; i++) {
            fprintf(fp, "F|%d|%d|%s\n",
                    FPHistory[i]->Row,
                    FPHistory[i]->Col,
                    FPHistory[i]->FileName);
            for (j=0;j<FPHistory[i]->BookCount;j++)
                fprintf (fp,"B|%d|%d|%s\n",
                         FPHistory[i]->Books[j]->Row,
                         FPHistory[i]->Books[j]->Col,
                         FPHistory[i]->Books[j]->Name);
        }
    }
    { // input history, store in reverse order to preserve order when loading
        for (int i = inputHistory.Count - 1; i >= 0; i--) {
            fprintf(fp, "I|%d|%s\n", inputHistory.Id[i], inputHistory.Line[i]);
        }
    }
    fclose(fp);
    return 1;
}

int LoadHistory(char *FileName) { /*FOLD00*/
    FILE *fp;
    char line[2048];
    char *p, *e;
    FPosHistory *last=NULL;
    HBookmark **nb;
    
    fp = fopen(FileName, "r");
    if (fp == 0)
        return 0;

    setvbuf(fp, FileBuffer, _IOFBF, sizeof(FileBuffer));

    if (fgets(line, sizeof(line), fp) == 0 ||
        strcmp(line, HISTORY_VER) != 0)
    {
        fclose(fp);
        return 0;
    }
    while (fgets(line, sizeof(line), fp) != 0) {
        if (line[0] == 'F' && line[1] == '|') { // file position history
            int r, c, L, R, M, cmp;
            p = line + 2;
            r = strtol(p, &e, 10);
            if (e == p)
                break;
            if (*e == '|')
                e++;
            else
                break;
            c = strtol(p = e, &e, 10);
            if (e == p)
                break;
            if (*e == '|')
                e++;
            else
                break;
            e = strchr(p = e, '\n');
            if (e == 0)
                break;
            *e = 0;
            last=NULL;
            if (UpdateFPos(p, r, c) == 0)
                break;
            // Get current file's record for storing bookmarks
            L=0;R=FPHistoryCount;
            while (L < R) {
                M = (L + R) / 2;
                cmp = filecmp(p, FPHistory[M]->FileName);
                if (cmp == 0) {
                    last=FPHistory[M];
                    break;
                } else if (cmp < 0) {
                    R = M;
                } else {
                    L = M + 1;
                }
            }
        } else if (line[0] == 'B' && line[1] == '|') { // bookmark history for last file
            if (last) {
                int r, c;
                p = line + 2;
                r = strtol(p, &e, 10);
                if (e == p)
                    break;
                if (*e == '|')
                    e++;
                else
                    break;
                c = strtol(p = e, &e, 10);
                if (e == p)
                    break;
                if (*e == '|')
                    e++;
                else
                    break;
                e = strchr(p = e, '\n');
                if (e == 0)
                    break;
                *e = 0;
                nb=(HBookmark **)realloc (last->Books,sizeof (HBookmark *)*(last->BookCount+1));
                if (nb) {
                    last->Books=nb;
                    nb[last->BookCount]=(HBookmark *)malloc (sizeof (HBookmark));
                    if (nb[last->BookCount]) {
                        nb[last->BookCount]->Row=r;
                        nb[last->BookCount]->Col=c;
                        nb[last->BookCount]->Name=strdup (p);
                        last->BookCount++;
                    }
                }
            }
        } else if (line[0] == 'I' && line[1] == '|') { // input history
            int i;
            
            p = line + 2;
            i = strtol(p, &e, 10);
            if (e == p)
                break;
            if (*e == '|')
                e++;
            else
                break;
            e = strchr(p = e, '\n');
            if (e == 0)
                break;
            *e = 0;
            AddInputHistory(i, p);
        }
    }
    fclose(fp);
    return 1;
}

int UpdateFPos(char *FileName, int Row, int Col) { /*fold00*/
    int L = 0, R = FPHistoryCount, M, N;
    FPosHistory *fp, **NH;
    int cmp;

    if (FPHistory != 0) {
        while (L < R) {
            M = (L + R) / 2;
            cmp = filecmp(FileName, FPHistory[M]->FileName);
            if (cmp == 0) {
                FPHistory[M]->Row = Row;
                FPHistory[M]->Col = Col;
                return 1;
            } else if (cmp < 0) {
                R = M;
            } else {
                L = M + 1;
            }
        }
    } else {
        FPHistoryCount = 0;
        L = 0;
    }
    assert(L >= 0 && L <= FPHistoryCount);
    fp = (FPosHistory *)malloc(sizeof(FPosHistory));
    if (fp == 0)
        return 0;
    fp->Row = Row;
    fp->Col = Col;
    fp->FileName = strdup(FileName);
    fp->Books = NULL;
    fp->BookCount = 0;
    if (fp->FileName == 0) {
        free(fp);
        return 0;
    }

    N = 64;
    while (N <= FPHistoryCount) N *= 2;
    NH = (FPosHistory **)realloc((void *)FPHistory, N * sizeof(FPosHistory *));
    if (NH == 0)
    {
        free(fp->FileName);
        free(fp);
        return 0;
    }

    FPHistory = NH;
    
    if (L < FPHistoryCount)
        memmove(FPHistory + L + 1,
                FPHistory + L,
                (FPHistoryCount - L) * sizeof(FPosHistory *));
    FPHistory[L] = fp;
    FPHistoryCount++;
    return 1;
}

int RetrieveFPos(char *FileName, int &Row, int &Col) { /*FOLD00*/
    int L = 0, R = FPHistoryCount, M;
    int cmp;

    if (FPHistory == 0)
        return 0;

    while (L < R) {
        M = (L + R) / 2;
        cmp = filecmp(FileName, FPHistory[M]->FileName);
        if (cmp == 0) {
            Row = FPHistory[M]->Row;
            Col = FPHistory[M]->Col;
            return 1;
        } else if (cmp < 0) {
            R = M;
        } else {
            L = M + 1;
        }
    }
    return 0;
}

int AddInputHistory(int Id, char *String) { /*FOLD00*/
    char *s = NULL; // get rid of a "might not be initialised" warning
    int i;
    // First check if it is already in list
    for (i = 0; i < inputHistory.Count; i++) {
        if (inputHistory.Id[i] == Id && strcmp(String, inputHistory.Line[i]) == 0) {
            // Found, will be moved to the beginning of list
            s = inputHistory.Line[i];
            break;
        }
    }
    if (s == NULL) {
        // Not in list
        s = strdup(String);
        if (inputHistory.Count < MAX_INPUT_HIST) {
            inputHistory.Count++;
            inputHistory.Line = (char **) realloc((void *) inputHistory.Line,
                                                  inputHistory.Count * sizeof(char *));
            inputHistory.Id = (int *) realloc((void *) inputHistory.Id,
                                              inputHistory.Count * sizeof(int *));
        } else {
            i--;
            free(inputHistory.Line[inputHistory.Count - 1]);
        }
    }

    memmove(inputHistory.Line + 1, inputHistory.Line, i * sizeof(char *));
    memmove(inputHistory.Id + 1, inputHistory.Id, i * sizeof(int *));
    inputHistory.Id[0] = Id;
    inputHistory.Line[0] = s;
    return 1;
}

int CountInputHistory(int Id) { /*FOLD00*/
    int i, c = 0;
    
    for (i = 0; i < inputHistory.Count; i++)
        if (inputHistory.Id[i] == Id) c++;
    return c;
}

int GetInputHistory(int Id, char *String, int len, int Nth) { /*fold00*/
    int i = 0;

    assert(len > 0);
    
    while (i < inputHistory.Count) {
        if (inputHistory.Id[i] == Id) {
            Nth--;
            if (Nth == 0) {
                strncpy(String, inputHistory.Line[i], len);
                String[len - 1] = 0;
                return 1;
            }
        }
        i++;
    }
    return 0;
}

/*
 * Get bookmarks for given Buffer (file) from history.
 */
int RetrieveBookmarks(EBuffer *buffer) { /*fold00*/
#ifdef CONFIG_BOOKMARKS
    int L = 0, R = FPHistoryCount, M,i;
    int cmp;
    HBookmark *bmk;
    char name[256+4] = "_BMK";
    EPoint P;

    assert(buffer!=NULL);
    if (FPHistoryCount==0) return 1;
    while (L < R) {
        M = (L + R) / 2;
        cmp = filecmp(buffer->FileName, FPHistory[M]->FileName);
        if (cmp == 0) {
            // Now "copy" bookmarks to Buffer
            for (i=0;i<FPHistory[M]->BookCount;i++) {
                bmk=FPHistory[M]->Books[i];
                strcpy (name+4,bmk->Name);
                P.Row=bmk->Row;P.Col=bmk->Col;
                if (P.Row<0) P.Row=0;
                else if (P.Row>=buffer->RCount) P.Row=buffer->RCount-1;
                if (P.Col<0) P.Col=0;
                buffer->PlaceBookmark(name,P);
            }
            return 1;
        } else if (cmp < 0) {
            R = M;
        } else {
            L = M + 1;
        }
    }
    return 1;
#else
    return 1;
#endif
}

/*
 * Store given Buffer's bookmarks to history.
 */
int StoreBookmarks(EBuffer *buffer) { /*fold00*/
#ifdef CONFIG_BOOKMARKS
    int L = 0, R = FPHistoryCount, M,i,j;
    int cmp;
    char *name;
    EPoint P;
    HBookmark *bmk;

    assert (buffer!=NULL);
    if (RetrieveFPos (buffer->FileName,i,j)==0) {
        // File not found in FPHistory -> add it
        if (UpdateFPos (buffer->FileName,0,0)==0) return 0;
    }
    // Now file is surely in FPHistory
    while (L < R) {
        M = (L + R) / 2;
        cmp = filecmp(buffer->FileName, FPHistory[M]->FileName);
        if (cmp == 0) {
            // First delete previous bookmarks
            for (i=0;i<FPHistory[M]->BookCount;i++) {
                bmk=FPHistory[M]->Books[i];
                if (bmk->Name) free (bmk->Name);
                free (bmk);
            }
            free (FPHistory[M]->Books);
            FPHistory[M]->Books=NULL;
            // Now add new bookmarks - first get # of books to store
            for (i=j=0;(i=buffer->GetUserBookmarkForLine(i,-1,name,P))>=0;j++);
            FPHistory[M]->BookCount=j;
            if (j) {
                // Something to store
                FPHistory[M]->Books=(HBookmark **)malloc (sizeof (HBookmark *)*j);
                if (FPHistory[M]->Books) {
                    for (i=j=0;(i=buffer->GetUserBookmarkForLine(i,-1,name,P))>=0;j++) {
                        bmk=FPHistory[M]->Books[j]=(HBookmark *)malloc (sizeof (HBookmark));
                        if (bmk) {
                            bmk->Row=P.Row;bmk->Col=P.Col;
                            bmk->Name=strdup (name);
                        } else {
                            // Only part set
                            FPHistory[M]->BookCount=j;
                            return 0;
                        }
                    }
                    return 1;
                } else {
                    // Alloc error
                    FPHistory[M]->BookCount=0;
                    return 0;
                }
            }
            return 1;
        } else if (cmp < 0) {
            R = M;
        } else {
            L = M + 1;
        }
    }
    // Should not get here
    return 0;
#else
    return 0
#endif
}

#endif
