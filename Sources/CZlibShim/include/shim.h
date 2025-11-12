#include <zlib.h>
#include <stddef.h>

int undercut_inflate(const unsigned char *input, size_t inputLength, unsigned char **output, size_t *outputLength);
