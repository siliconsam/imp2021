#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#define nl '\n'

#ifdef NO_RANGE_CHECK
//Important that n is only ever evaluated once, as side-effects (++) would break it
#define RANGECHECK(n) (n)
#else
int RANGECHECK(int n, int low,int high, char *name, int line) {
  if ((n < low) || (n > high)) {
    fprintf(stderr, "* Array bounds exceeded at line %d: %s(%d)\n", line, name, n);
    exit(0);
  }
  return n;
}
#endif

FILE **instream = NULL;
FILE **outstream = NULL;

FILE *grammarstream = NULL, *glist = NULL, *errorstream = NULL, *dlist = NULL, *tablestream = NULL;

void Exit(int i, int L) {
  fprintf(stderr, "Error exit %d at line %d\n", i, L);
  exit(i);
}
#define exit(n) Exit(n,__LINE__)

void readsymbol(int *ch) {
  *ch = fgetc(*instream);
  if (feof(*instream)) {
    fprintf(stderr, "* Unexpected End of file\n");
    exit(1);
  }
}
int nextsymbol(void) {
  int ch = fgetc(*instream);
  if (feof(*instream)) {
    fprintf(stderr, "* Unexpected End of file\n");
    exit(1);
  }
  ungetc(ch, *instream);
  return ch;
}
void skipsymbol(void) {
  (void)fgetc(*instream);
  if (feof(*instream)) {
    fprintf(stderr, "* Unexpected End of file\n");
    exit(1);
  }
}
void space(void) {
  fprintf(*outstream, " ");
}
void spaces(int n) {
  while (--n >= 0) space();
}
void newline(void) {
  fprintf(*outstream, "\n");
}
void newlines(int n) {
  while (--n >= 0) newline();
}
void printsymbol(int ch) {
  fputc(ch, *outstream);
}
void printstring(char *s) {
  fprintf(*outstream, "%s", s);
}
//============================================================================
int main (int argc, char **argv) {
  // takeon: convert imp grammar 31/1/77
  //const int grammarstream = 1;

  // in streams
  //const int errorstream = 0, tablestream = 1, glist = 2, dlist = 3;

  // out streams
  const int firstphrase = 200;
  const int ident = 90;
  static int charmax = 0, nmax = -1, inits = 0;
  static int newname = 0, outstring = -1;
  int sym;
  //int count;
  int gmin;
  int gmax;
  int kmax;

  unsigned char Char_[1400];
#define Char(x) Char_[RANGECHECK(x,1,1400,"main:Char",__LINE__)-1]    

  static unsigned char tran_[256];
#define tran(x) tran_[RANGECHECK(x,0,256,"tran",__LINE__)]

  int index_[256];
#define index(x) index_[RANGECHECK(x,0,256,"index",__LINE__)]      

  int item_[802];
#define item(x) item_[RANGECHECK(x,-1,800,"item",__LINE__)+1]        

  int next_[802];
#define next(x) next_[RANGECHECK(x,-1,800,"next",__LINE__)+1]        

  int atomic_[179 - 130 + 1];
#define atomic(x) atomic_[RANGECHECK(x,130,179,"atomic",__LINE__)-130]    

  int phrase_[255 - 200 + 1];
#define phrase(x) phrase_[RANGECHECK(x,200,255,"phrase",__LINE__)-200]    

  int initial_[256];
#define initial(x) initial_[RANGECHECK(x,0,255,"initial",__LINE__)]  

  int initnext_[256];
#define initnext(x) initnext_[RANGECHECK(x,0,255,"initnext",__LINE__)]

  int keydict_[1023 - 32 + 1];
#define keydict(x) keydict_[RANGECHECK(x,32,1023,"keydict",__LINE__)-32]  

  auto void hwrite (int n, int m) {
    if (n & 0x8000) n |= 0xFFFF0000;
    fprintf(*outstream, "%*d", m, n);
  }

  auto void readsym (void) {
    for (;;) {
      do { readsymbol (&sym); } while (sym == ' ');
      if ((sym != '&') || (nextsymbol() != nl)) return;
      skipsymbol ();
    }
  }

  void read(int *n_) {
    #define n *n_
    n = 0;
    readsym();
    if (!isdigit(sym)) {
      printstring("Not a number: "); printsymbol(sym); newline ();
      exit(1);
    }
    for (;;) {
      n = n*10 + (sym-'0');
      if (!isdigit(nextsymbol())) break;
      readsymbol(&sym);
    }
    #undef n  
  }

  auto void printchars (int p) {
    int flag;

    flag = outstring;
    if (p) {
      while ((Char (p) && flag)) {
        flag -= 1;
        printsymbol (Char (p++) & 127);
      }
    }
  }

  auto void printname (int n) {
    printchars (index(n & 255));
    while ((n & 0x300) != 0) {
      printsymbol ('<');
      n -= 256;
    }
    if (outstring < 0) {
      if ((n & 0x800) || tran (n & 255)) printsymbol ('"');
      n >>= 16;
      if (n) { printsymbol ('['); hwrite (n, 0); printsymbol (']'); }
    }
  }

  auto void readname (int *n_) {
    #define n *n_
    int i, j, k, m;

    i = charmax;
    for (;;) {
      Char (++i) = sym;
      readsymbol (&sym);
      if (! ((('A' <= sym) && (sym <= 'Z')) || (('0' <= sym) && (sym <= '9'))) ) break;
    }
    Char (++i) = 0;
    if (sym == ' ') readsym ();
    m = nmax;
    while (m >= 0) {
      j = index(m);
      k = charmax + 1;
      while (j && ((Char (j) & 127) == Char (k))) {
        if (!Char (k)) goto ok;
        j += 1; k += 1;
      }
      m -= 1;
    }
  ok:
    if (newname) {
      if (m >= 0) {
        printstring ("DUPLICATE: "); printchars (charmax + 1); newline ();
      }
      index(n) = charmax + 1;
      charmax = i;
      if (sym == '"') {
        tran (n) = 1;
        readsym ();
      }
      if (nmax < n) nmax = n;
    } else {
      if (m < 0) {
        printstring ("UNKNOWN: "); printchars (charmax + 1); newline ();
        m = 0;
      }
      n = m;
    }
#undef n
  }

  auto void readgrammar (void) {
    int i, j, k, l, p, min, max, exp, end;

    int converted[350 + 200 + 1];
#define converted(x) converted[RANGECHECK(x,-200,350,"converted",__LINE__)+200]      

    int head[200];
#define head(x) head[RANGECHECK(x,-200,-1,"head",__LINE__)+200]        

    int tail[200];
#define tail(x) tail[RANGECHECK(x,-200,-1,"tail",__LINE__)+200]        

    int token[350];
#define token(x) token[RANGECHECK(x,1,350,"token",__LINE__)-1]      

    int link[350];
#define link(x) link[RANGECHECK(x,1,350,"link",__LINE__)-1]        

    int map[801];
#define map(x) map[RANGECHECK(x,0,800,"map",__LINE__)]          

    auto int cell (int h, int t) {
      // creates a list cell, if necessary, with head h and tail t
      int i;
      i = t;
      if (i > 0) i = 0;
      while (i-- != min) {
        if (((head (i) == h) && (tail (i) == t))) return (i);
      }
      head (--min) = h; tail (min) = t;
      converted (min) = 0;
      return (min);
    }

    auto int union_ (int x, int y) {
      int hx, hy;

      if (x == y) return (x);
      if (x < y) { hx = x; x = y; y = hx; }
      if (x >= 0) {
        if (y >= 0) return (cell (x, y));
        hy = head (y);
        if (x > hy) return (cell (x, y));
        if (x != hy) return (cell (hy, union_ (x, tail (y))));
        return (y);
      }
      hx = head (x);
      hy = head (y);
      if (hx > hy) return (cell (hx, union_ (tail (x), y)));
      if (hx != hy) return (cell (hy, union_ (x, tail (y))));
      return (cell (hx, union_ (tail (x), tail (y))));
    }

    auto void concatenate (int x, int y) {
      int i = x, j;
      do { j = link (i); link (i) = y; i = j; } while (i != x);
    }

    auto void acceptexp (int *exp_, int *expend_) {
      #define exp *exp_
      #define expend *expend_
      // inputs a regular expression
      // and creates intermediate graph representation
      int i, string, stringend, unit, unitend, n;

      exp = 0;
    s:
      string = 0;
    u:
      if (sym == '(') {
        readsym ();
        acceptexp (&unit, &unitend);
        if ((!unit) || (sym != ')')) goto err;
        readsym ();
      } else {
        if ((('A' <= sym) && (sym <= 'Z')) || (sym == '%')) {
          readname (&i);
          if (i) Char (index(i)) |= 128;
          i |= (tran (i) << 11);
          while (sym == '<') {
            i += 256;
            readsym ();
          }
          if (sym == '"') {            // force transparent
            readsym ();
            i |= 1 << 11;
          }
          if (sym == '[') {
            read (&n);
            if ((n >> 4) != 0) goto err;
            i += (n << 16);
            readsym ();
            if (sym != ']') goto err;
            readsym ();
          }
        } else {
          if (sym != '+') goto err;
          i = 0;
          while (sym == '+') {
            i += 256;
            readsym ();
          }
        }
        token (++max) = i;
        link (max) = max;
        unit = max;
        unitend = max;
      }
      if ((sym == '*') || (sym == '!')) {
        token (++max) = -1;
        link (max) = max;
        head (--min) = max;
        tail (min) = unit;
        concatenate (unitend, min);
        unitend = max;
        if (sym == '*') unit = min;
        readsym ();
      }
      if (sym == '?') {
        token (++max) = -1;
        link (max) = link (unitend);
        link (unitend) = max;
        head (--min) = max;
        tail (min) = unit;
        unit = min;
        readsym ();
      }
      if (string == 0) string = unit; else concatenate (stringend, unit);
      stringend = unitend;
      if ((sym != ',') && (sym != ')') && (sym != nl)) goto u;
      if (!exp) {
        exp = string;
        expend = stringend;
      } else {
        exp = union_ (string, exp);
        i = link (expend);
        link (expend) = link (stringend);
        link (stringend) = i;
      }
      if (sym != ',') return;
      do readsym (); while (sym == nl);
      goto s;
    err:
      exp = 0;
      #undef exp
      #undef expend
    }

    auto void convert (void) {
      int i, j, k, m, n, gmax1, loopstop;

      auto void tcount (int x) {
        int t;

        for (;;) {
          if (x == 0) return;
          if (x < 0) { tcount (tail (x)); x = head (x); }
          t = token (x);
          if (t >= 0) break;
          if (t == loopstop) return;
          token (x) = loopstop;
          x = link (x);
        }
        k -= 1;
      }

      auto void addcomponents (int x) {
        static int i, k, t, u;

        while (x) {
          if (x < 0) { addcomponents (tail (x)); x = head (x); }
          if ((t = token (x)) >= 0) break;
          if (t == loopstop) return;
          token (x) = loopstop; x = link (x);
        }
        if (x) x = link (x); else t = 0;
        u = t & (0xF0000 + (15 << 11) + 255);
        i = gmax1;
        for (;;) {
          if (++i > gmax) break;
          k = item (i);
          if (k == t) {
            next (i) = union_ (next (i), x);
            return;
          }
          if ((k & (0xF0000 + (15 << 11) + 255)) == u) {
            if (p) printname (p);
            printstring ("-CLASH: ");
            printname (k); space (); printname (t);
            newline ();
          }
          k = k & 255;
          if ((u == ident) || (((u & 255) < k) && (k >= 180)) || (k == 0)) {
            int initial_i = i;
            for (i = gmax; i >= initial_i; i -= 1) {  // %cycle i = gmax,-1,i
              fprintf(stderr, "%d: item(%d) = %d (%x)\n", __LINE__, i+1, item(i), item(i));
              item (i + 1) = item (i);
              next (i + 1) = next (i);
            }
            break;
          }
        }
        gmax += 1;
        fprintf(stderr, "%d: item(%d) = %d (%x)\n", __LINE__, i, t, t);
        item (i) = t;
        next (i) = x;
      } // addcomponents

      loopstop = -1; gmin = gmax + 1;
      for (i = min; i <= max; i += 1) {
        converted (i) = 0;
      }
      n = next (0);
    l1:
      gmax1 = gmax;
      loopstop -= 1;
      addcomponents (n);
      item (gmax) += 1024;
      if (!gmax1) {
        inits = gmax;
        while (inits && (item ((inits) & 255) >= firstphrase)) inits -= 1;
      }
      converted (n) = gmax1 + 1;
      m = 0;
      for (i = gmin; i <= gmax; i += 1) {
        j = next (i);
        if (j) {
          k = converted (j);
          if (!k) {
            loopstop -= 1;
            tcount (j);
            converted (j) = k;
          }
          if (k < m) {
            m = k; n = j;
          }
        }
      }
      if (m) goto l1;
      for (i = gmin; i <= gmax; i += 1) {
        k = next (i);
        if (k) k = converted (k);
        next (i) = k;
      }
    }
    // convert

    auto void minimize (void) {
      int i, j, k, m, n;
      int stack[150];
#define stack(x) stack[RANGECHECK(x,1,150,"stack",__LINE__)-1]      

      auto int ultmap (int i) {
        int j;
        do { j = i; i = map (i); } while ((i != j) && (i != 0));
        return (j);
      }

      auto int equivalent (int nn, int mm) {
        int i, j, k, pos1, pos2;

        pos1 = pos2 = 0;
      l1:
        for (;;) {
          k = item (mm);
          if (item (nn) != k) goto l9;
          i = next (nn);
          j = next (mm);
          if ((!i && j) || (i && !j)) goto l9;
          stack (++pos1) = nn;
          map (nn++) = mm++;
          if (k & 1024) break;              // last alternative
        }
      l2:
        if (pos2++ == pos1) return (1);
        i = stack (pos2);
        nn = ultmap (next (i));
        mm = ultmap (next (map (i)));
        if (nn == mm) goto l2;
        if (nn < mm) { i = nn; nn = mm; mm = i; } // swap
        if (nn > n) goto l1;
      l9:
        while (pos1) {
          i = stack (pos1--);
          map (i) = i;;
        }
        return (0);
      }
      for (i = 0; i <= gmax; i += 1) { map (i) = i; }
      if (gmin > gmax) return;
      for (n = gmin; n <= gmax; n += 1) {
        if (map (n) == n) {
          if ((n == gmin) || (item (n - 1) & 1024)) {
            m = 1;
            while (m != n) {
              if ((map (m) == m) && equivalent (n, m)) break;
              m += 1;
            }
          }
        } else {
          map (n) = ultmap (n);
        }
      }
      j = gmin - 1;
      for (i = gmin; i <= gmax; i += 1) {
        k = map (i);
        if (k == i) {
          map (i) = ++j;
          item (j) = item (i); next (j) = next (i);
        } else {
          map (i) = map (k);
        }
      }
      gmax = j;
      for (i = gmin; i <= gmax; i += 1) {
        k = next (i);
        if (k) next (i) = map (k);
      }
    } // minimize
    
    gmax = 0;
  l1:
    do { readsym (); } while (sym == nl);
    if (sym == '/') goto l10;
    if ((sym == 'S') && (nextsymbol() == 'S')) {
      skipsymbol (); p = 0;
    } else {
      readname (&p); if (!p) exit (0);
    }
    min = 0; max = 0;
    do { readsym (); } while (!(((sym != nl) && ((sym != '-') && (sym != '>')))));
    acceptexp (&exp, &end);
    if ((!exp) || (sym != nl)) goto l9;
    concatenate (end, 0);
    item (0) = 2047; next (0) = exp;
    convert ();
    i = gmin;
    minimize ();
    i = map (gmin);
    if (!p) {  // ss
      
      // !! j = item(i);! k = next(i)
      // !! k = k-inits;! %stop %if k <= 0
      // !! %if i <= inits %start
      // !! ->l99 %if l >= first phrase
      // !! %signal 0,25 %if initial(l) # 0
      // !! %else
      // !! %finish
      // !! gmax = gmax-inits

      fprintf(stderr, "******************* %d\n", __LINE__);
      for (i = 1; i <= inits; i += 1) {
        fprintf(stderr, "A ******************* %d  i=%d  l=%d item(i)=%d\n", __LINE__, i, l, item(i));
        l = item (i) & 255;
        fprintf(stderr, "B ******************* %d  i=%d  l=%d  initial[l] = %d\n", __LINE__, i, l, initial (l));
        if (l >= 200) continue;
        if ((130 <= l) && (l < 180)) l = atomic (l);
        if (initial (l)) exit(1);
        initial (l) = i; initnext (l) = item (i);
        fprintf(stderr, "C ******************* %d  i=%d  l=%d  initial[l] = %d\n", __LINE__, i, l, initial (l));
      }
      fprintf(stderr, "******************* 4\n");
      outstream = &glist;
      newline ();
    } else {
      phrase (p) = i;
      outstream = &glist;
      newline ();
      printname (p); printstring (" =>"); hwrite (i, 1);
    }
    k = 1024;
    for (i = gmin; i <= gmax; i += 1) {
      if (k & 1024) {
        newline ();
        hwrite (i, 3);
        j = 0;
      }
      if (++j > 5) { newline (); spaces (4); j = 1; }
      spaces (3);
      k = item (i);
      if (k & 255) {
        printname (k);
      } else {
        printstring ("*E");
        while (k & 0x300) { printsymbol ('+'); k -= 256; }
      }
      hwrite (next (i), 1);
    }
    outstream = &errorstream;
    goto l1;
  l9:
    printstring ("WRONG FORMAT AT: ");
    while (sym != nl) { printsymbol (sym); readsym (); }
    newline ();
    goto l1;
    // deal with initial phrase
    // assumes exactly one (imp)
  l10:
    if (inits == 1) {      // not imp!!!
      outstream = &errorstream;
      printstring ("NOT AN IMP GRAMMAR");
      newline ();
      return;
    }
    if (!(p = phrase (item (inits + 1) & 255))) exit(1);
    for (;;) {
      j = item (p); k = j & 255;
      if (k >= 160) exit(1);
      if (k >= 120) k = atomic (k);
      if (initial (k)) exit(1);
      initial (k) = p | 0x8000; initnext (k) = j;
      if (j & 1024) break;
      p += 1;
    }
    initial (0) = initial (182);    // %decl
    outstream = &glist;
    newlines (2);
    for (i = 0; i <= 119; i += 1) {
      k = initial (i);
      if (k) {
        hwrite (i, 2); printstring (":  "); printname (initnext (i)); hwrite (k & 255, 3);
        if (k < 0) printsymbol ('`');
        newline ();
      }
    }
    outstream = &errorstream;
  }  // read grammar

  auto void readatoms (void) {
    int i, j;
    //int k;
    int dict, dmax, code, class, sub;
#undef Char
    int Char_inner[1001], cont[1001], alt[1001];
#define Char(x) Char_inner[RANGECHECK(x,0,1000,"readatoms:Char",__LINE__)]    
#define cont(x) cont[RANGECHECK(x,0,1000,"cont",__LINE__)]        
#define alt(x) alt[RANGECHECK(x,0,1000,"alt",__LINE__)]          

    auto void readcode (void) {
      int n;
      code = nextsymbol(); sub = 0;
      if ((code != ',') && (code != nl)) {
        skipsymbol ();
        if (code == '$') {
          read (&code); return;
        }
        if (code != '(') return;
        read (&sub);
        while (nextsymbol() == '+') {
          skipsymbol (); read (&n); sub += n;
        }
        skipsymbol ();
      }
      code = class + 128;
    }

    auto void insertin (int *x_) {
      #define x *x_
      for (;;) {
        while (Char (x) < code) {
          if (!cont (x)) cont (x) = sub;
          x_ = &alt (x) /* Pointer assignment */ ;
        }
        if (Char (x) != code) {
          dmax += 1; Char (dmax) = code;
          cont (dmax) = 0; alt (dmax) = x; x = dmax;
        }
        if (code & 128) break;
        readcode ();
        x_ = &cont (x) /* Pointer assignment */ ;
      }
      if (!sub && alt (x)) sub = cont (alt (x));
      cont (x) = sub;
      #undef x
    }

    auto void store (int x) {
      int m,n,v, mm, q;

      for (;;) {
        n = ++kmax;
        m = alt (x); mm = m;
        if (m) { store (m); m = 0x8000; }
        v = Char (x); x = cont (x);
        if (v & 128) break;
        if (!m) {  // no alternatives
          if (!alt (x) && !(Char (x) & 128)) {
            v += Char (x) << 7; x = cont (x);
          }
        } else {
          q = kmax - n + 1;
          if (q >> 7) {
            outstream = &errorstream;
            printstring ("Keydict overflow!"); newline ();
            exit (0);
          }
          v = (q << 7) + (v | 0x8000);          // or v = ((q << 7) + v) | 0x8000; ??
        }
        keydict (n) = v;
      }
      if (!mm) {
        keydict (++kmax) = 0;
      } else {
        kmax -= 1;
      }
      keydict (n) = m + 0x4000 + ((keydict (n + 1) & 127) << 7) + (v & 127);
      keydict (n + 1) = x;
    }

    auto void display (int i, int s) {
      int j;

      auto void show (int sym) {
        if (sym == nl) sym = '$';
        printsymbol (sym);
      }
      
      for (;;) {
        j = keydict (i);
        if (!(j & 0x4000)) {
          show (j & 127);
          if (!(j & 0x8000)) {
            j >>= 7;
            if (j) { show (j); s += 1; }
            space ();
            i += 1; s += 2;
          } else {
            space ();
            display (((j >> 7) & 127) + i, s + 2);
            if (!(j >> 15)) break;
            spaces (s);
            i += 1;
          }
        } else {
          printsymbol (':'); printname (j & 127);
          if ((j >> 7) & 127) {
            space (); printname ((j >> 7) & 127);
          }
          j = keydict (i + 1) & 0x3FFF;
          if (j) hwrite (j, 4);
          newline ();
          break;
        }
      }
    }
    dict = 0; dmax = 0; Char (0) = 999;
  l1:
    for (;;) {
      sym = nextsymbol();
      if ((sym != '[') && (sym != nl)) break;
      do { readsymbol (&sym); } while (sym != nl);
    }
    if (sym == '/') goto l10;
    read (&class);
    newname = 1;
    readsym (); readname (&class);
    newname = 0;
    if (class < 130) {
      if (sym != '[') {
        if (sym == '$') read (&sym);
        for (;;) {
          code = sym; insertin (&dict);
          readsymbol (&sym);
          if (sym != ',') break;
          do { readsymbol (&sym); } while ((sym == ' ') || (sym == nl));
        }
      }
    } else {
      if ((class <= firstphrase) && (sym == '=')) {
        readsym ();
        readname (&atomic (class));
      }
    }
    while (sym != nl) readsymbol (&sym);
    goto l1;
    
  l10:
    outstream = &dlist; newlines (2);
    kmax = 126; keydict (32) = 0;
    for (i = 33; i <= 126; i += 1) {
      printsymbol (i); space ();
      if (Char (dict) == i) {
        j = (kmax + 1) << 2;
        store (cont (dict));
        dict = alt (dict);
        display (j >> 2, 2);
      } else {
        printsymbol ('?'); newline ();
        j = 32 << 2;
      }
      // let:0 dig:1 term:2 other:3
      if (!(('A' <= i) && (i <= 'Z'))) j += 3;
      if (('0' <= i) && (i <= '9')) j -= 2;
      if (i == ';') j -= 1;
      keydict (i) = j;
    }
    // WTF! Following assignment blocks the use of ~ eg ~=
    // So, assignment commented out.
    // keydict('~') = keydict('^')
    newlines (2);
    outstream = &errorstream;
#undef Char
  }

  auto int packed (int j, int k) {
    j = ((j & 1024) << 5) + ((j & 0x0300) << 4) + (((j >> 3) & 0x0100) << 6) + ((j >> 8) & 0xF00);
    return j + (k & 255);
  }

  int i, j, k;
  charmax = 0;

  glist = fopen("i77.grammar.list", "w");
  errorstream = stderr;
  dlist = fopen("i77.grammar.dict", "w");
  tablestream = fopen("i77.tables-new.imp", "w");
  grammarstream = fopen("i77.grammar", "r");
  
  for (i = -1; i <= 800; i += 1) { item (i) = 0; next (i) = 0; }
  for (i = 0; i <= 255; i += 1) { index (i) = 0; initnext (i) = 0; initial (i) = 0; }
  for (i = 130; i <= 179; i += 1) { atomic (i) = i; }
  for (i = firstphrase; i <= 255; i += 1) { phrase (i) = 0; }

  instream = &grammarstream;
  outstream = &errorstream;
  do { readsymbol (&i); } while (i != '/');
  do { readsymbol (&i); } while (i != nl);

  readatoms ();
  do { readsymbol (&i); } while (i != nl);
  readgrammar ();

  // write required values
  outstream = &tablestream;
  printstring ("   %endoflist"); newline ();

  const int namesperline = 8;
  printstring ("%conststring(8)%array text(0:255) = %c"); newline ();
  printstring ("\"Z\",");
  // we have just output the first name already
  // so initialise k with good value
  k = namesperline - 1; outstring = 8;
  for (j = 1; j <= 255; j += 1) {
    printsymbol ('"'); printname (j); printsymbol ('"');
    if (j != 255) printsymbol (',');
    if (--k <= 0) { k = namesperline; newline (); }
  }
  newline ();
  outstring = -1;
  printstring ("%constinteger gmax1="); hwrite (gmax, 0); newline ();
  printstring ("%owninteger gmax="); hwrite (gmax, 0); newline ();
  printstring ("%constinteger imp phrase ="); hwrite (inits + 1, 0); newlines (2);

  printstring ("!  FLAG<1> 0<1> SS<2> 0<3> T<1> LINK<8>"); newline ();
  printstring ("%constshortintegerarray initial(0:119) = %c");
  for (i = 0; i <= 119; i += 1) {
    if (!(i & 7)) newline ();
    hwrite (initial (i), 7);
    if (i != 119) printsymbol (',');
  }
  newlines (2);
  
  printstring ("%constbyteintegerarray atomic(130:179) = %c");
  k = 0;
  for (i = 130; i <= 179; i += 1) {
    if (!(k++ & 7)) newline ();
    hwrite (atomic (i), 3);
    if (i != 179) printsymbol (',');
  }
  newlines (2);
  printstring ("%ownshortintegerarray phrase(200:255) = %C");
  for (i = 200; i <= 255; i += 1) {
    if (!(i & 7)) newline ();
    hwrite (phrase (i), 3);
    if (i != 255) printsymbol (',');
  }
  newlines (2);
  
  printstring ("!  MORE<1> 0<1> ORDER<2> TYPE<4> CLASS<8>"); newline ();
  printstring ("%ownshortintegerarray gram(0:max grammar) = %c");
  for (i = 0; i <= gmax; i += 1) {
    if (!(i & 7)) newline ();
    k = 0;
    if (i) k = packed (item (i) ^ 1024, item (i));
    hwrite (k, 7); printsymbol (',');
  }
  newline ();
  printstring ("0(max grammar-gmax1)"); newlines (2);
  printstring ("%ownshortintegerarray glink(0:max grammar) = %c");
  for (i = 0; i <= gmax; i += 1) {
    if (!(i & 7)) newline ();
    hwrite (next (i), 7); printsymbol (',');
  }
  newline ();
  printstring ("0(max grammar-gmax1)"); newlines (2);

  printstring ("%constshortinteger max kdict = "); hwrite (kmax, 0); newline ();
  printstring ("%constshortintegerarray kdict(32:max kdict) = %c");
  for (i = 32; i <= kmax; i += 1) {
    if (!(i & 7)) newline ();
    hwrite (keydict (i), 7);
    if (i != kmax) printsymbol (',');
  }
  newline ();
  printstring ("   %list"); newline ();
  printstring ("%endoffile"); newline ();

  outstream = &errorstream;
  printstring ("Grammar complete"); newline ();
  exit(0);
  return 1;
}
