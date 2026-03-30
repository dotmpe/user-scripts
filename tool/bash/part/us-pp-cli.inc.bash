# Copyright: (C) 2026 hari <hari@t470p>
#
# Distributed under terms of the MIT license.

userscripts::preproc::build_main ()
{
: alias us_build_main
: about 'Shortcut to build <target> from <target>.build'
  local exec=0 check=1
  while (($#))
  do case "$1" in
    ( --update ) check=0 ;;
    ( --run | --exec ) exec=1 ;;
    ( * ) false ;;
    esac && shift || break
  done
  : "${1%.us-build}"
  : "${_%.build}"
  local script_build=${_}
  [[ $1 != "$script_build" ]] || {
    set -- "$1.us-build" "${@:2}"
    #set -- "$1.build" "${@:2}"
  }
  if [[ $(command -v $script_cmdname) -ef "$script_build" ]]
  then
    >&2 echo "$script_cmdname $$: Warning: should probably not overwrite currently running script"
    script_build+=.new
  fi
  # TODO: need to check the whole include list here. but not sure where to store
  # that yet. probably track name/target mapping in user data
  if ! ((check)) || {
    # mapfile -t deps < "$us_pp_output.inc.list"
    [[ $script_build -ot $1 ]]
  }
  then
    userscripts::preproc::main "$@" ||
      failerr "E$? Building ${script_build}" || return
    std_noo diff -bqr "$script_build" "$us_pp_output.i" || {
      >"$script_build" <"$us_pp_output.i" cat
      ((QUIET)) || echo "Updated $script_build"
    }
  fi
  if ((exec))
  then chmod +x "$script_build" && exec "$script_build" "${@}"; fi
}

userscripts::preproc::gpp ()
{
: alias _us_gpp
  # Standard GPP user/meta modes for reference:
  # User mode arguments:
  # 1. macro start sequence
  # 2. macro end seq
  # 3. argument start seq
  # 4. arg separator
  # 5. arg end seq
  # 6. arg balancing stack character list
  # 7. unstack char list
  # 8. number reference string
  # 9. quote char
  gpp_default_user_mode=(
    "" "" "(" "," ")" "(" ")" "#" "\\"
  )
  # Meta-macro arguments
  # 1. macro start seq
  # 2. macro end seq
  # 3. arg start seq
  # 4. arg sep seq
  # 5. arg end seq
  # 6. arg bal stack char list
  # 7. arg bal unstack char list
  gpp_default_meta_mode=(
    "#" "\n" " " " " "\n" "(" ")"
  )
  gpp_c_compat_mode=(
    -n -U "" "" "(" "," ")" "(" ")" "#" ""
    -M "\n#\w" "\n" " " " " "\n" "" ""
    +c "/*" "*/" +c "//" "\n" +c "\\\n" ""
    +s "\"" "\"" "\\" +s "'" "'" "\\"
  )
  gpp_tex_like_mode=(
    -U "\\" "" "{" "}{" "}" "{" "}" "#" "@"
  )
  gpp_default_mode=(
    -U "${gpp_default_user_mode[@]}"
    -M "${gpp_default_meta_mode[@]}"
  )
  # Custom mode that seems to work for shell (and strips unix line comments)
  gpp_shell_mode=(
    # XXX: any \ occurence is captured by the PP unless quoted
    +s "\"" "\"" "\\"
    +s "'" "'" "\\"
    # XXX: strip comments
    #+c "\n#\b" "\n"
    #+c "\n#\n" ""
  )
  # Testing; could not get {% ... %} syntax to work
  gpp_jinja_mode=(
    -U "{% " " %}" "(" "," ")" "({}" "})" "#" "\""
  )
  gpp_xxx_mode=(
    -U "${default_user_mode[@]}"
    -M "{%" " %}" "%" " " "\n" "(" ")"
  )
  declare -n argv=gpp_${1}
  argv+=( -I$HOME/bin -DLANG=$us_pp_lang )
  command gpp "${argv[@]:?}" "${@:2}"
}

userscripts::preproc::main ()
{
: alias us_pp_main
  local -a files=() gppargs=()
  local run_gpp=1 run_us_pp=1 output=0 exec=0 file first_script
  while (($#))
  do case "$1" in
    ( --gpp ) ;;
    ( --no-gpp ) run_gpp=0 ;;
    ( --no-process ) run_us_pp=0 ;;
    ( --output ) output=1 ;;
    ( --process ) ;;
    ( --exec ) exec=1 ;;
    ( --help ) userscripts::preproc::main_help "${@:2}"; return ;;
    ( -- ) false ;;
    ( --* ) userscripts::preproc::main_help "$@"; return 1 ;;
    ( -* ) gppargs+=( "$1" ) ;;
    ( * ) [[ -f $1 ]] && files+=( "$1" ) || false
    esac && shift || break
  done
  ((${#files[*]})) ||
    failerr "$$ us-pp: Preprocessor expects input file argument" || return
  # XXX: want to share/access some, output in particular
  #local us_pp_{input,shebang,lang,inputreal,output,linecomment}
  us_pp_linecomment="#"
  for file in "${files[@]}"; do
    if [[ ! -f "${file}" ]]
    then failerr "$$ us-pp: File input expected: ${file@Q}" || return; fi
    if ((run_us_pp))
    then _us_pp_procfile "$file" ||
        failerr "$$ us-pp: E$? processing ${file@Q}" || return
      if ! ((run_gpp)); then
        if ((output))
        then cat "$us_pp_output"
        else [[ ${first_script-} ]] || first_script=$us_pp_output; fi
      else
        # XXX: script is not compatible with cpp/g++. But need to recurse to
        # get proper sources list.
        #cpp -M "$us_pp_output" > "$us_pp_output.inc.list"
        # List all root includes
        #grep -Po '^#include <\K.*$' "$us_pp_output" | tr -d '>' > "$us_pp_output.inc.list"
        _us_gpp shell_mode "${gppargs[@]}" -o "$us_pp_output.i" "$us_pp_output" ||
          failerr "$$ us-pp: E$? running gpp ${us_pp_output}" || return
        ((QUIET)) || >&2 echo "$$ us-gpp: ready: $us_pp_output.i"
        if ((output)); then
          cat "$us_pp_output.i"
        else [[ ${first_script-} ]] || first_script=$us_pp_output.i; fi; fi
    else
      #cpp -M "$file" > "$file.inc.list"
      #grep -Po '^#include <\K.*$' "$file" | tr -d '>' > "$file.inc.list"
      _us_gpp shell_mode "${gppargs[@]}" -o "$file.i" "$file" ||
        failerr "$$ us-pp: E$? running gpp ${file}" || return
      ((QUIET)) || >&2 echo "$$ us-gpp: ready: $file.i"
      if ((output)); then
        cat "$file.i"
      else [[ ${first_script-} ]] || first_script=$file.i; fi; fi
  done
  if ((exec))
  then chmod +x "$first_script" && exec "$first_script" "${@}"; fi
}

userscripts::preproc::main_help ()
{
  local cmd=${0##*/} sub=${1-}
  local us_pp_main_man='~ - super simple preprocessor in shell script

Usage:
    ~ [infile]
    ~ <<EOM
\#define FOO This is \
   a multiline definition.
\#define GREET(name) Hello, name!
GREET(Alice)
GREET(Bob)
\\GREET(Charly)
EOM

TODO: build-in pp main inc docstrings
'
  local -A us_pp_main_sub_man=(
    [--gpp]='Use GPP to produce script file'
    [--no-gpp]='Do not add second pass GPP'
    [--no-process]='Do not run us-pp, only GPP'
    [--output]='Output after processing'
    [--process]='Use us-pp to produce script from input'
    [--exec]='Execute the produced script file'
    [--help]='Shows manual or command description'
    [-*]='Argument for GPP'
    [--]='Abort argument processing. Pass rest of arguments to executed script'
    [*]='Considered as file input, abort argument processing if non-existent file'
  )
  ! (($#)) || {
    local -n _doc='us_pp_main_sub_man["$sub"]'
    [[ ${_doc:+set} ]] || sub=--$sub
    [[ ${_doc:+set} ]] || failerr "$script_cmdname: No such command $cmd ${1@Q}" || return
    echo "$cmd $sub: $_doc"
    return
  }
  echo "${us_pp_main_man//"~"/"$cmd"}"
  echo
  echo "Options:"
  printf.lines.array-map us_pp_main_sub_man
}

userscripts::preproc::run_main ()
{
: alias us_run_main
: about 'Shortcut for us-build --run'
# to use in /usr/bin/env shebang if that supports just one argument, but not
# even sure that applies ever
  userscripts::preproc::build_main --run "$@"
}

userscripts::preproc::update_main ()
{
: alias us_update_main
: about 'Shortcut for us-build --update'
# to use in /usr/bin/env shebang if that supports just one argument, but not
# even sure that applies ever
  userscripts::preproc::build_main --update "$@"
}

# Id: us-pp-cli                                  vim:set ft=bash sw=2 sts=2 et:
