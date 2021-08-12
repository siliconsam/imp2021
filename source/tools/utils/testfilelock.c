#include <stdio.h>

    if (file)
    {
        // lock file
        _lock_file(file);
        while ((nread = fread(buf, 1, sizeof buf, file)) > 0)
        {
            fwrite(buf, 1, nread, out);
        }
        // unlock the file
        _unlock_file(file);
        fclose(file);
        fclose(out);
    }
