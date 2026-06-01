#
# Copyright 2018-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.

userscripts::preproc::_debug ()
{
: private-prefix _us_pp
  ((QUIET)) || ! ((DEBUG)) || >&2 echo "$$ $script_cmdname: $1"
}

userscripts::preproc::_notice ()
{
: private-prefix _us_pp
  ((QUIET)) || >&2 echo "$$ $script_cmdname: $1"
}

userscripts::preproc::build_main ()
{
: alias us_build_main
: about 'Shortcut to build <target> from <target>.build (wrapper for us-pp main)'
  local exec=0 check=1 _pp_opts _file_arg=() {dest,srcs}file
  while (($#))
  do case "$1" in
    ( --update ) check=0 ;;
    ( --run | --exec ) exec=1 ;;
    #( --output=* ) destfile=${1:9} ;;
    ( --sources=* ) srcsfile=${1:10} _pp_opts+=( "$1" ) ;;
    ( -- ) shift; false ;;
    ( -* ) _pp_opts+=( "$1" ) ;;
    ( * ) [[ ${#_file_arg[*]} -lt 2 ]] && _file_arg+=( "$1" ) ;;
    esac && shift || break
  done
    # srcsfile="$us_pp_output.inc.list"
  local -n _input='_file_arg[0]'
  local -n _output='_file_arg[1]'
  [[ ${_input:+set} ]] ||
    failerr "Input file argument expected" || return
  if [[ ${_output:+set} ]]
  then
    build_target=$_output
    unset "${!_output}"
  else
    : "${_input%.us-build}"
    : "${_%.build}"
    local build_target=${_}
    [[ ${_input} != "$build_target" ]] || {
      _input+=${us_pp_build_ext:-.us-build}
    }
  fi
  [[ -f $_input ]] ||
    failerr "Input file expected ${_input@Q}" || return
  # TODO: need to check the whole include list here. but not sure where to store
  # that yet. probably track name/target mapping in user data
  if [[ ! -s "$build_target" ]] || ! ((check)) || {
    local srcs _test
    _test+=( "$_input" -nt "$build_target" )
    if [[ ${srcsfile:+set} && ! -s "${srcsfile-}" ]]; then
      mapfile -a srcs < "$srcsfile"
      for src in "${srcs[@]}"
      do _test+=( -o "$src" -nt "$build_target" )
      done
    fi
    ! ((DEBUG)) ||
      >&2 declare -p _test
    test "${_test[@]}"
  }
  then
    _pp_opts+=( --output="$build_target.new" )
    userscripts::preproc::main "${_pp_opts[@]}" "${_file_arg[@]}" ||
      failerr "E$? Building ${build_target}" || return
    test -s "$build_target.new" ||
      failerr "Output expected ${_file_arg[*]@Q}" || return
    if [[ $(command -v $script_cmdname) -ef "$build_target.new" ]]
    then
      >&2 echo "$script_cmdname $$: Warning: should probably not overwrite currently running script"
    fi
    if std_noo diff -bqr "$build_target.new" "$_output"; then
      _us_pp_debug "No updates for $build_target"
      rm "$build_target.new"
    else
      <"$build_target.new" >"$build_target" cat &&
      rm "$build_target.new" &&
      _us_pp_notice "Updated $build_target" || return
    fi
  else
    #! ((DEBUG)) ||
    #>&2 declare -p build_target check _input srcsfile || true
    #>&2 echo "${!_input}=$_input"
    _us_pp_notice "No check or UTD"
  fi
  if ((exec))
  then
    [[ ${build_target:0:1} == / ]] &&
    : "$build_target" || : "./${build_target}"
    chmod +x "$_" && exec "$_" "${@}"
  fi
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
    -C
    #-n -U "" "" "(" "," ")" "(" ")" "#" ""
    #-M "\n#\w" "\n" " " " " "\n" "" ""
    #+c "/*" "*/" +c "//" "\n" +c "\\\n" ""
    #+s "\"" "\"" "\\" +s "'" "'" "\\"
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
  )
  gpp_shell_nc_mode=( "${gpp_shell_mode[@]}"
    # XXX: strip comments
    +c "\n#\b" "\n"
    +c "\n#\n" ""
  )
  # Testing; could not get {% ... %} syntax to work
  gpp_jinja_mode=(
    -U "{% " " %}" "(" "," ")" "({}" "})" "#" "\""
  )
  gpp_xxx_mode=(
    -U "${default_user_mode[@]}"
    -M "{%" " %}" "%" " " "\n" "(" ")"
  )
  declare -n argv=gpp_${1}_mode
  [[ ${argv:+set} ]] ||
    failerr "us:gpp: No such mode ${1@Q}" || return
  shift
  local tag path
  local -a args
  local -n _sub='us_gpp_subs["$tag"]'
  [[ ! ${us_pp_lang:+set} ]] ||
    [[ ${us_gpp_subs["LANG"]:+set} ]] || args+=( -D"LANG=$us_pp_lang" )
  for tag in "${us_gpp_defs[@]}"
  do
    args+=( -D"${tag}${_sub:+=$_sub}" )
  done
  for path in "${us_pp_incs[@]}"
  do
    args+=( -I"${path}" )
  done
  _us_pp_debug "> command gpp ${args[*]@Q} ${argv[*]@Q} ${*@Q}"
  command gpp "${args[@]}" "${argv[@]}" "${@}"
}

userscripts::preproc::main ()
{
: alias us_pp_main
  _us_pp_debug "> $FUNCNAME: ${*@Q}"
  local -a files=() gppargs=()
  local -I us_pp_off
  : "${us_pp_off:+0}"
  local run_gpp=1 run_us_pp=${_:-1} output=0 exec=0 {dest,srcs,}file first_script
  # FIXME: isolate these vars better from env
  local do_outline=0 do_modeline=0 # us_pp_{{in,out}put,lang}
  local -I us_gpp_mode
  local -I us_pp_ext
  local -I us_pp_outliner
  : "${us_pp_ext:=.i}"
  do_outline=${us_pp_outliner:+1}
  : "${us_pp_outliner:=default_outliner}"
  while (($#))
  do case "$1" in
    ( --exec | --run ) exec=1 ;;
    ( --ext=* ) us_pp_ext=${1:6} ;;
    ( --gpp=* ) us_gpp_mode=${1:6} ;;
    ( --help ) userscripts::preproc::main_help "${@:2}"; return ;;
    ( --lang=* ) : "${us_pp_lang:=${1:7}}" ;;
    ( --no-gpp ) run_gpp=0 ;;
    ( --no-modeline ) do_modeline=0 ;;
    ( --no-outline ) do_outline=0 ;;
    ( --no-process ) run_us_pp=0 ;;
    ( --modeline ) do_modeline=1 ;;
    ( --outline ) do_outline=1 do_modeline=1 ;;
    ( --outline=* ) do_outline=1 do_modeline=1 us_pp_outliner=${1:9} ;;
    ( --output ) output=1 ;;
    ( --output=* ) destfile=${1:9} ;;
    # TODO: find other places and try to build from parts/rules+ constraints
    ( --debug ) declare -x DEBUG=1 ;;
    ( --verbose ) declare -x VERBOSE=1 ;;
    ( --pwd ) : "${EWD:=$PWD}"
        declare -x EWD
      ;;
    ( --sources=* ) srcsfile=${1:10} ;;
    ( -- ) shift; false ;;
    ( --* ) userscripts::preproc::main_help "$@"; return 1 ;;
    ( - ) files+=( "$1" ) ;;
    ( -* ) gppargs+=( "$1" ) ;;
    ( * ) [[ -f $1 ]] && files+=( "$1" ) || false
    esac && shift || break
  done
  : "${us_gpp_mode:=shell}"
  ((${#files[*]})) ||
    failerr "$$ us-pp: Preprocessor expects input file argument" || return
  # XXX: want to share/access some, output in particular
  #local us_pp_{input,shebang,lang,inputreal,output,linecomment}
  us_pp_linecomment="#"
  local -n _ext=us_pp_ext
  for file in "${files[@]}"; do
    if [[ $file == - ]]
    then [[ ! -t 0 ]] ||
      failerr "$$ us-pp: Input expected" || return
    elif [[ ! -f ${file} ]]
    then failerr "$$ us-pp: File input expected: ${file@Q}" || return; fi
    if ((run_us_pp))
    then _us_pp_procfile "$file" ||
        failerr "$$ us-pp: E$? processing ${file@Q}" || return
      if ! ((run_gpp)); then
        _us_pp_notice "us-pp: ready: $us_pp_output"
        if ((output))
        then cat "$us_pp_output"
        else [[ ${first_script-} ]] || first_script=$us_pp_output; fi
      else
        _us_gpp ${us_gpp_mode} "${gppargs[@]}" -o "$us_pp_output$_ext" "$us_pp_output" ||
          failerr "$$ us-pp: E$? running gpp ${us_pp_output}" || return
        _us_pp_notice "us-gpp: ready: $us_pp_output$_ext"
        if ((output)); then
          cat "$us_pp_output$_ext"
        else [[ ${first_script-} ]] || first_script=$us_pp_output$_ext; fi; fi
    else
      _us_pp_notice "Skipped PP"
      _us_gpp ${us_gpp_mode} "${gppargs[@]}" -o "$file$_ext" "$file" ||
        failerr "$$ us-pp: E$? running gpp ${file}" || return
      _us_pp_notice "us-gpp: ready: $file$_ext"
      if ((output)); then
        cat "$file$_ext"
      else [[ ${first_script-} ]] || first_script=$file$_ext; fi; fi
  done
  # Store included file list if requested
  if ((run_us_pp)) && [[ ${srcsfile:+set} ]]
  then
    > "$srcsfile" printf '%s\n' "${us_pp_sources[@]}"
    _us_pp_debug "us-pp: wrote input list to $srcsfile"
  fi
  # Truncate target and insert generated script lines if requested
  if [[ ${destfile:+set} ]]
  then
    if [[ $(command -v $script_cmdname) -ef "$destfile" ]]
    then
      <"$first_script" >"$destfile.new" cat
      _us_pp_notice "Updates for/at $destfile{,.new}"
    else
      <"$first_script" >"$destfile" cat; fi; fi
  # Fork to target script if requested
  if ((exec))
  then [[ ${first_script:0:1} == / ]] &&
    : "$first_script" || : "./${first_script}"
    chmod +x "$_" && exec "$_" "${@}"; fi
}

userscripts::preproc::main_help ()
{
  _us_pp_debug "> $FUNCNAME: ${*@Q}"
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
  _us_pp_debug "> $FUNCNAME: ${*@Q}"
# to use in /usr/bin/env shebang if that supports just one argument, but not
# even sure that applies ever
  userscripts::preproc::build_main --run "$@"
}

userscripts::preproc::update_main ()
{
: alias us_update_main
: about 'Shortcut for us-build --update'
  _us_pp_debug "> $FUNCNAME: ${*@Q}"
# to use in /usr/bin/env shebang if that supports just one argument, but not
# even sure that applies ever
  userscripts::preproc::build_main --update "$@"
}

# Id: us-pp-cli                                  vim:set ft=bash sw=2 sts=2 et:
