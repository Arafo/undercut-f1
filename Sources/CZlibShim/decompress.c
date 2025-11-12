#include "shim.h"
#include <stdlib.h>

int undercut_inflate(const unsigned char *input, size_t inputLength, unsigned char **output, size_t *outputLength) {
    if (input == NULL || output == NULL || outputLength == NULL) {
        return Z_STREAM_ERROR;
    }

    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.next_in = (Bytef *)input;
    stream.avail_in = (uInt)inputLength;

    int status = inflateInit2(&stream, -MAX_WBITS);
    if (status != Z_OK) {
        return status;
    }

    size_t capacity = inputLength * 4 + 1024;
    if (capacity < 4096) {
        capacity = 4096;
    }

    Bytef *buffer = (Bytef *)malloc(capacity);
    if (buffer == NULL) {
        inflateEnd(&stream);
        return Z_MEM_ERROR;
    }

    stream.next_out = buffer;
    stream.avail_out = (uInt)capacity;

    while ((status = inflate(&stream, Z_NO_FLUSH)) == Z_OK) {
        if (stream.avail_out == 0) {
            size_t newCapacity = capacity * 2;
            Bytef *newBuffer = (Bytef *)realloc(buffer, newCapacity);
            if (newBuffer == NULL) {
                free(buffer);
                inflateEnd(&stream);
                return Z_MEM_ERROR;
            }
            stream.next_out = newBuffer + capacity;
            stream.avail_out = (uInt)(newCapacity - capacity);
            buffer = newBuffer;
            capacity = newCapacity;
        }
    }

    if (status != Z_STREAM_END) {
        free(buffer);
        inflateEnd(&stream);
        return status;
    }

    *output = buffer;
    *outputLength = capacity - stream.avail_out;

    inflateEnd(&stream);
    return Z_OK;
}
