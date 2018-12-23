# User Scripts Manual: File formats and conventions

*Log-Like*        A command or function call where the signature corresponds to
                  ```
                  ~ header-type [header] description [context] [status]
                  ```
                  Where header and context are used for what their names
                  suggest, ie. loosely for a key, and a list of tags resp.
                  Their use includes as target and sources e.g. for use in
                  make or redo target rules.

                  Exact support for Header type and other field tags varies.
