---
date: 2024-5-15
title: strtok源码
tags: c语言
categories: 技术
---

# strtok源码分析

```c
#include <string.h>
#include <stdio.h>

int main () {
   char str[80] = "192.168.10.110:9000";
   char *pszHost = strtok(str, ":");
   char *pszPort = strtok(NULL, ":");
   printf("%s\n", pszHost);
   printf("%s\n", pszPort);
   return(0);
}

```

输出

```
192.168.10.110
9000
```


- https://codebrowser.dev/glibc/glibc/string/strtok.c.html


```c
/* Parse S into tokens separated by characters in DELIM.
   If S is NULL, the last string strtok() was called with is
   used.  For example:
	char s[] = "-abc-=-def";
	x = strtok(s, "-");		// x = "abc"
	x = strtok(NULL, "-=");		// x = "def"
	x = strtok(NULL, "=");		// x = NULL
		// s = "abc\0=-def\0"
*/
char *
strtok (char *s, const char *delim)
{
  static char *olds;  // 保留上一次的位置
  return __strtok_r (s, delim, &olds);
}



/* Parse S into tokens separated by characters in DELIM.
   If S is NULL, the saved pointer in SAVE_PTR is used as
   the next starting point.  For example:
	char s[] = "-abc-=-def";
	char *sp;
	x = strtok_r(s, "-", &sp);	// x = "abc", sp = "=-def"
	x = strtok_r(NULL, "-=", &sp);	// x = "def", sp = NULL
	x = strtok_r(NULL, "=", &sp);	// x = NULL
		// s = "abc\0-def\0"
*/
char *
__strtok_r (char *s, const char *delim, char **save_ptr)
{
  char *end;
  if (s == NULL)
    s = *save_ptr;
  if (*s == '\0')
    {
      *save_ptr = s;
      return NULL;
    }
  /* Scan leading delimiters.  */
  s += strspn (s, delim);
  if (*s == '\0')
    {
      *save_ptr = s;
      return NULL;
    }
  /* Find the end of the token.  */
  end = s + strcspn (s, delim);
  if (*end == '\0')
    {
      *save_ptr = end;
      return s;
    }
  /* Terminate the token and make *SAVE_PTR point past it.  */
  *end = '\0'; // 设置结束符
  *save_ptr = end + 1;  // 指针移动到下一个位置
  return s;
}

```