#
# Copyright 2018-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.

userscripts::preproc::_op_define ()
{
: private-prefix _us_pp
  local lk=define:${current_dir}

# TODO: use param for lang or other keys/attrs
  [[ ! ${current_param:+set} ]] ||
    failerr "Unexpected parameter(s) ${current_param@Q}" || return
  #us_pp_param["$current_dir"]=$current_param
  us_pp_snip["$current_dir"]=$current_block
  us_pp_snip_literal["$current_dir"]=$current_literal
  ((QUIET)) || >&2 echo "Defined ${current_dir} = ${current_block@Q}"
}

userscripts::preproc::_op_generate ()
{
: private-prefix _us_pp
  local lk=generate:${current_dir}
  case "$current_dir" in

  ( about )
      : "${current_block:0:-1} "
      : "${_//$'\n'# /$'\n'}"
      : "${_%%[# ]}"
      : "${_##[# ]}"
      ABOUT_HEAD=$_
      : "${SCRIPT_ABOUT_HEAD:=$ABOUT_HEAD}"
      local _lc=$us_pp_linecomment
      # XXX: should really check if text starts with linebreak to insert space
      : "$_lc ${SCRIPT_ABOUT_HEAD//$'\n'/$'\n'$_lc }"
      echo "${_//# $'\n'/#$'\n'}"
    ;;

  ( * ) failerr "No such generated block ${current_dir@Q}"
    ;;

  esac
}

userscripts::preproc::_op_snippet ()
{
: private-prefix _us_pp
  local lk=snippet:${current_dir} us_include=${U_S:?}/tool/us/include
  _pp_inc () {
    if ((current_literal))
    then if ((run_gpp))
      then echo "#include <user-script.$1>"
      else cat "$us_include/user-script.$1"
      fi
    else
      _us_pp_unshift_source "$us_include/user-script.$1"
    fi
  }
  _pp_inc_src () {
    ! ((current_literal)) || >&2 echo "Warn: Source is not literal: ${current_dir@Q}: $1"
    _us_pp_unshift_source "$us_include/user-script.$1"
  }
  case "$current_dir" in
  ( debug | us-debug )    _pp_inc       'debug.sh.h' ;;
  ( log | us-log )        _pp_inc_src   'log.sh.h' ;;
  ( strict | us-strict )  _pp_inc       'strict.sh.h' ;;
  ( us-host-profile )     _pp_inc       'host-profile.sh.h' ;;
  ( us-basedir )          _pp_inc       'ewd.bash.h' ;;
  ( us-build-config )     _pp_inc       'build.config.bash.h' ;;
  ( us-configure )        _pp_inc_src   'configure.bash.h' ;;
  ( us-package )          _pp_inc       'package.bash.h' ;;
  ( verbosity | us-build-verbosity )
                          _pp_inc       'build-verbosity.bash' ;;

  ( * )
      local -n _dir=current_dir
      local -n _snip='us_pp_snip["$_dir"]'
      local -n _snip_lit='us_pp_snip_literal["$_dir"]'
      [[ ${_snip:+set} ]] ||
        failerr "No such snippet or definition ${_dir@Q}" || return

      ((current_literal)) || {
        ((_snip_lit)) || >&2 echo "Warn: Source is not literal ${_dir@Q}"
      }
      local _new="${_snip//"{{$_dir.content}}"/"$current_param"}"
      ((_snip_lit)) && echo -n "$_new" || _us_pp_unshift_lineblock _new

  esac
}

userscripts::preproc::_op_special ()
{
: private-prefix _us_pp
  local lk=special:$current_dir
  case "$current_dir" in

  ( data )
      [[ ${current_param:+set} ]] ||
        failerr "$lk: Expected parameter(s) ${current_dir@Q}" || return
      local file rest
      read -r file rest <<< "$current_param"
      [[ ! ${rest:+set} ]] || failerr "Surplus parameter(s) ${rest@Q}" || return
      . "$file" ||
        failerr "E$? while loading ${file@Q}"
    ;;

  ( declare-ifndef )
      [[ ${current_param:+set} ]] ||
        failerr "$lk: Expected parameter(s) ${current_dir@Q}" || return
      local -a args
      read -r -a args <<< "$current_param"
      _us_pp_debug ":declare-ifndef ${args[*]@Q}"
      # XXX: see :declare for latest routine
      # sh_generate_declare ...
      [[ $us_pp_lang = bash ]] ||
        failerr "TODO: Conditional declare for $us_pp_lang" 125 || return
      local a k v
      case "${args[0]}" in
        ( -p )
            for a in "${args[@]:1}"
            do
              k=${a%%=*}
              [[ $k != "$a" ]] ||
                failerr "Key=value pattern expected: ${a@Q}" || return
              v=${a: ${#k}+1}
              printf ': "${%s:=%s}"\n' "$k" "$v"
            done ;;
        ( -f )
            for a in "${args[@]:1}"
            do
              if_ok "$(declare -f "$a")" ||
                failerr "Function not found: ${a@Q}" || return
              printf 'if_ok "$(declare -F "%s")" ||\n%s\n' "$a" "$_"
            done ;;
        ( * ) failerr "Ilegal $current_dir flag ${args[0]}" || return
      esac
    ;;

  ( declare )
      [[ ${current_param:+set} ]] ||
        failerr "$lk: Expected parameter(s) ${current_dir@Q}" || return
      local -a args
      read -r -a args <<< "$current_param"
      _us_pp_debug ":declare ${args[*]@Q}"
      # TODO: parse flags, see define
      # XXX: bash format
      declare "${args[@]}"
    ;;

  ( define )
      [[ ${current_param:+set} ]] ||
        failerr "$lk: Expected parameter(s) ${current_dir@Q}" || return
      local -a args
      read -r -a args <<< "$current_param"
      [[ ${#args[*]} -gt 0 ]] ||
        failerr "$lk: Cannot parse parameter(s)" || return
      [[ ${#args[*]} -eq 1 ]] || {
        [[ ${args[1]:0:1} != '(' ]] || failerr "TODO macro functions" || return
      }
      # TODO: parse flags
      local -n _tag='args[0]'
      local -n _sub='us_gpp_subs["$_tag"]'
      [[ ${_sub:+set} ]] || us_gpp_defs+=( "$_tag" )
      [[ ${#args[*]} -eq 1 ]] &&
      _sub= || _sub="${args[*]:2}"
    ;;

  ( generator )
      # ((DEV))
      #echo "GENERATOR=\"$$/$0 from ${us_pp_input@Q} at $(date --iso=sec)\""
      echo "GENERATOR=\"$$/$script_cmdname from ${us_pp_input@Q} at $(date --iso=sec)\""
    ;;

  ( include )
      [[ ${current_param:+set} ]] ||
        failerr "$lk: Expected parameter(s) ${current_dir@Q}" || return
      : "${us_pp_incs[*]}"
      local name rest src ext path=${_// /:}
      read -r name rest <<< "$current_param"
      [[ ! ${rest:+set} ]] ||
        failerr "Surplus parameter(s) ${rest@Q}" || return
      ! ((DEBUG)) || ((QUIET)) ||
        >&2 echo "Resolving $current_dir $name"
      for ext in .build "" .bash
      do src=$(PATH=$path command -v "$name$ext") && break
      done
      [[ -f "$src" ]] ||
        failerr "Unable to resolve ${name@Q}" || return
      _us_pp_unshift_source "$src"
    ;;

  ( license )
      [[ ! ${current_param:+set} ]] ||
        failerr "$lk: Unexpected parameter(s) ${current_param@Q}" || return
      # Generate from template if set empty or LICENSE.head is missing
      [[ ${PROJECT_LICENSE_HEAD+set} ]] || {
        [[ ! -e LICENSE.head ]] || PROJECT_LICENSE_HEAD=$(< LICENSE.head)
      }
      [[ ${PROJECT_LICENSE_HEAD-} ]] && {
        # XXX: should really check if text starts with linebreak
        : "$us_pp_linecomment ${PROJECT_LICENSE_HEAD//$'\n'/$'\n'$us_pp_linecomment }"
        echo "${_//# $'\n'/#$'\n'}"
      } || {
        : "${USER:=$(whoami)}"
        : "${HOST:=$(hostname)}"
        YEAR=$(date +%Y)
        USERINFO=${USER}@${HOST}
        lines_prefix "$us_pp_linecomment " << EOM

Copyright $YEAR $USER <$USERINFO>

Distributed under terms of the ${FILE_LICENSE:-MIT} license.
EOM
        }
    ;;

  ( modeline ) [[ ${us_pp_lang} = bash ]] ||
          failerr "$lk: Unsupported build langauge ${us_pp_lang}" || return
        [[ ${us_pp_lang} = bash ]] && {
          #echo "# ex:ft=bash:"
          echo "# ${current_param:-vim:set ft=bash sw=2 sts=2 et:}"
        }
      ;;

  ( * ) failerr "No such special ${current_dir@Q}" || return
  esac
}

userscripts::preproc::_op_template ()
{
: private-prefix _us_pp
  local lk=template:${current_dir}
  case "$current_dir" in
    ( expand )
        local {key,value,map}name _x rest
        read -r {key,value,map}name rest <<< "$current_param"
        [[ ${mapname:+set} ]] || {
          [[ ${valuename:+set} ]] ||
            failerr "expand directive expects array value and arguments" || return
          mapname=$valuename
          valuename=$keyname
          keyname=_x
        }
        local -n _map=$mapname _value="${mapname}[\"\$_key\"]"
        [[ ${_map[*]:+set} ]] ||
          failerr "No data found for array: ${mapname@Q}" || return

        local _str _key _new
        for _key in "${!_map[@]}"
        do
          : "${current_block}"
          : "${_//\{$keyname\}/$_key}"
          : "${_//\{$valuename\}/$_value}"
          _new+=$_
        done

        ((current_literal)) &&
        echo -n "$_new" || _us_pp_unshift_lineblock _new
      ;;

  ( * ) failerr "No such template dir ${current_dir@Q}"
    ;;

  esac
}

# XXX: only bashunit.mpe still uses this, see _procfile
userscripts::preproc::_prepfile ()
{
: private-prefix _us_pp
  us_pp_input=${2}
  local _firstline="$(head -n 1 "${2}")"
  [[ $_firstline == "#!"* ]] && {
    us_pp_shebang=${_firstline:2}
    : "${us_pp_shebang##*/}"
    : ${_#* }
    us_pp_alias=$_
    if [[ $us_pp_alias == *.* ]]
    then us_pp_program=${us_pp_alias%.*} us_pp_lang=${us_pp_alias##*.}
    else us_pp_lang=${us_pp_alias}
    fi
  } || {
    us_pp_lang=${2##*.}
    case "$us_pp_lang" in ( build | us-build )
        : "${2%.*}"
        : "${_##*.}"
        us_pp_lang=${_}
    esac
  }
  us_pp_inputreal="$(realpath "${2}")"
  : "${us_pp_inputreal%/*}"
  : "${us_pp_inputreal##*/},${_//\//-}${1}"
  us_pp_output=/tmp/${_}
  _us_pp_run
}

userscripts::preproc::_process_loop () {
: private-prefix _us_pp
  declare -ga us_pp_sources
  _us_pp_open_filesource () {
    exec {new_fd}<"$1" ||
        failerr "E$? opening FD for file ${1@Q}" || return
    us_pp_sources+=( "$1" )
    ! ((DEBUG)) || ((QUIET)) ||
      >&2 echo "Reading from ${1@Q} (FD #${new_fd})"
  }
  _us_pp_unshift_source () {
    local new_fd
    _us_pp_open_filesource "$1" &&
    # NOTE read is at end of stack, so unshift is just push
    us_pp_input_stack+=( "$new_fd" )
  }
  _us_pp_concat_source () {
    local new_fd
    _us_pp_open_filesource "$1" &&
    # NOTE read is at end of stack, so concat is actually unshift
    us_pp_input_stack=( "$new_fd" "${us_pp_input_stack[@]}" )
  }
  _us_pp_unshift_lineblock() {
    local new_fd
    local -n _str=${1}
    exec {new_fd}<<<"$_str" ||
        failerr "E$? opening FD for string ${1}" || return
    us_pp_input_stack+=( "$new_fd" )
    ! ((DEBUG)) || ((QUIET)) ||
      >&2 echo "Using string input from ${FUNCNAME[1]} at FD #${new_fd}"
  }
  _us_pp_readline ()
  {
    local _cur_fd=${us_pp_fd}
    if ! IFS= read -r us_pp_line <&$us_pp_fd
    then
      #XXX: try: close
      exec {us_pp_fd}<&- &&
      unset ${!us_pp_fd} || {
        us_pp_fail_stat=$?
        us_pp_fail_fd=$_cur_fd
        failerr "E$? closing FD $_cur_fd" $us_pp_fail_stat || return
      }
      #/
      (( ${#us_pp_input_stack[*]} == 0 )) && return ${_E_break:?}
      return ${_E_next:?}
    fi
    ! ((DEBUG)) || ((QUIET)) ||
      >&2 echo "FD $us_pp_fd read line ${us_pp_line@Q}"
  }

  # Prepare to run different directives
  local -A us_pp_op=(
    ['%']=define
    ['<']=template
    ['>']=generate
    ['&']=snippet
    [':']=special
  )
  local -n _op='us_pp_op["$current_op"]'
  local current_{block,dir,literal,op,param}
  local us_pp_{line,nest}
  local -n us_pp_fd='us_pp_input_stack[-1]'
  local -a us_pp_input_stack

  # First apply static script as filter on input
  [[ ${us_pp_lang-} ]] ||
    failerr "Language expected for prefilter" || return
  if [[ ! ${us_pp_filter-} ]]
  then
    exec {new_fd}<"$us_pp_input"
  else
    exec {new_fd}< <(< "$us_pp_input" . <(echo "${us_pp_filter}"))
  fi
  us_pp_sources+=( "$us_pp_input" )
  us_pp_input_stack=( "$new_fd" )

  if ((do_outline))
  then
    declare -ga us_pp_outline{,_tags}
    us_pp_outline_level=0
  fi

  # Main processing loop: read one line at a time, from last FD on stack until
  # all inputs are read
  while true
  do
    _us_pp_readline || {
      # TODO: when in outliner, do individual SOF/EOF plus final end-of-input event
      test $_E_next -eq $? && continue || {
        test $_E_break -eq $_ && break || return $_
      }
    }
    if case "$us_pp_line" in
    ( \#[\&:]* ) # Match aliases
        current_op=${us_pp_line:1:1}
        read -r current_dir current_param <<< "${us_pp_line:2}"
        [[ ${current_dir:0:1} == "'" ]] &&
        current_dir=${current_dir:1:-1} current_literal=1 ||
          current_literal=0
      ;;
    ( \#[\<\>%]* ) # Match block definitions
        current_op=${us_pp_line:1:1}
        read -r current_dir current_param <<< "${us_pp_line:2}"
        [[ ${current_dir:0:1} == "'" ]] &&
        current_dir=${current_dir:1:-1} current_literal=1 ||
          current_literal=0
        # Read block
        us_pp_nest=1
        while true
        do
          _us_pp_readline || {
            test $_E_next -eq $? && continue || {
              test $_E_break -eq $_ || return $_
              failerr "E$_ while reading $current_dir block" $_ || return
              failerr "EOF while reading $current_dir block from $us_pp_fail_fd" $_ || return
            }
          }
          if [[ ${us_pp_line} == "#$current_op$current_dir"* ||
                ${us_pp_line} == "#$current_op'$current_dir'"* ]]
          then ((us_pp_nest+=1))
          elif [[ ${us_pp_line} == "#/${current_dir}" ]]
          then
            ((us_pp_nest-=1)) || break
          fi
          current_block+=${us_pp_line}$'\n'
        done
      ;;
    ( '#!'[\!\ ]* ) # Interpret or discard outline header text lines
        ((do_outline)) || continue
        _us_pp_scan_${us_pp_outliner:?} || return
        continue
      ;;
    ( '#!'* ) # Replace shebang
        >/dev/null 2>&1 command -v $us_pp_lang ||
          >&2 echo "Warning: Entering shebang for inaccessible interpreter ${us_pp_lang@Q}"
        echo "#!/usr/bin/env $us_pp_lang"
        continue ;;
    ( '##'* ) # Reformat to normal cpp/gpp directive
        us_pp_line=${us_pp_line:1}
        false ;;
    ( '#'* ) continue ;; # Strip all other comments or directives
    ( * ) false ;; # Pass-through line, no processing
    esac; then
      _us_pp_op_${_op} || {
        test $_E_next -eq $? || return $_
      }
      unset current_{block,dir,literal,op,param}
      continue
    fi
    # XXX: another feature; accept bash \-continuations
    ! ((${run_gpp:-0})) || {
      # escape unquated? continuations so they do not get lost
      [[ ${us_pp_line: -1:1} != "\\" ]] || {
        us_pp_line="$us_pp_line\\"
      }
    }
    echo "$us_pp_line"
  done
}

userscripts::preproc::_procfile ()
{
: private-prefix _us_pp
: about 'Setup input and output and invoke _run to process and write files'
: extended 'Helper for us-pp main. '
  # XXX: do shebang AND modeline scanning if process mode is not entirely clear
  us_pp_input=${1:?}
  us_pp_output=${2-}
  if [[ $us_pp_input == - ]]
  then
    us_pp_input=/dev/stdin
    ! ((DEBUG)) || ((QUIET)) ||
      >&2 echo "Reading from standard input"
    ! ((do_modeline)) ||
      _ failerr "Cannot read modeline from standard input (ignored)"
  else
    if ((do_modeline)); then
      if_ok "$(tail -n 1 "$us_pp_input")" &&
      _us_pp_scan_modeline "${_:1}" ||
        failerr "E$? file peek for ${us_pp_input@Q} modeline" || return
    fi
  fi

  if [[ ! ${us_pp_lang:+set} ]]; then
    if [[ $us_pp_input == /dev/stdin ]]
    then
      failerr "Cannot read shebang from standard input" || return
    fi
    if [[ ${us_pp_output:+set} && "$us_pp_output" == *.* ]]
    then us_pp_lang=${us_pp_output##*.}
    else
      local _firstline="$(head -n 1 "${1}")"
      if [[ $_firstline == "#!"* ]]
      then
        us_pp_shebang=${_firstline:2}
        : "${us_pp_shebang##*/}"
        local arg _cmdline=( ${_#* } )
        for arg in "${_cmdline[@]}"
        do
          case "$arg" in
          ( env ) ;;
          ( -* ) ;;
          ( * ) us_pp_alias=$arg; break ;;
          esac
        done

        if [[ $us_pp_alias == *.* ]]
        then us_pp_program=${us_pp_alias%.*} us_pp_lang=${us_pp_alias##*.}
        else us_pp_lang=${us_pp_alias}
        fi
      else
        us_pp_lang=${us_pp_input##*.}
      fi
    fi
  fi

  # XXX: us-build CLI is too primitive but dont feel like focussing on that rn
  >/dev/null 2>&1 command -v $us_pp_lang ||
    >&2 echo "us-pp: Warning: Inaccessible language interpreter ${us_pp_lang@Q}"

  if [[ ! ${us_pp_output:+set} ]]
  then
    us_pp_inputreal="$(realpath "${us_pp_input}")"
    : "${us_pp_inputreal%/*}"
    : "${us_pp_inputreal##*/},${_//\//-}.mpe.$us_pp_lang"
    us_pp_output=/tmp/${_}
  fi

  # Generate and return status
  _us_pp_run
}

userscripts::preproc::_run ()
{
: private-prefix _us_pp
  ((QUIET)) || >&2 echo "$$ us-pp: reading: $us_pp_input"
  _us_pp_writefile || return
  ((QUIET)) || >&2 echo "$$ us-pp: done: $us_pp_output"
}

userscripts::preproc::_scan_default_outliner ()
{
: private-prefix _us_pp
: about 'Read text into level headers and parse roles and tags format'
  local word headerread=0
  local -n _tags='us_pp_outline_tags[$us_pp_outline_level]'  _header='us_pp_outline[-1]'
  : "${us_pp_line:1}"
  : "${_//[^A-Za-z0-9_()#\!\$@%\&*|,\.:=+-]/ }"
  for word in $_
  do case "$word" in
      ( "!"* )
          : "${word##[^!]*}"
          ((us_pp_outline_level+=${#_}))
          us_pp_outline+=( "" )
        ;;
      ( "~"* ) ;;
      ( "+"* )
          TODO "Add project context tag"
          _tags+=( "$word" )
        ;;
      ( "@"* )
          TODO "Add generic context tag"
          _tags+=( "$word" )
        ;;
      ( * ) _header+="${_header:+ }$word" ;;
    esac
  done
}

userscripts::preproc::_scan_modeline ()
{
: private-prefix _us_pp
: about 'Parse language and outliner info from text'
  local word
  local -n _tags
  # FIXME: parse prefixed blocks properly
  : "${*//[^A-Za-z0-9_=:-]/ }"
  for word in ${_//:/ }
  do case "$word" in

      ( pwd ) : "${EWD:=$PWD}"
          declare -x EWD
        ;;

      ( gpp-mode=* ) us_gpp_mode=${word:9}; return ;;
      ( *:gpp-mode=*:* )
          : "${word##*:gpp-mode=}"
          : "${_%%[: ]*}"
          us_gpp_mode=$_; return ;;

      ( ft=* ) us_pp_lang=${word:3}; return ;;
      ( *:ft=*:* )
          : "${word##*:ft=}"
          : "${_%%[: ]*}"
          us_pp_lang=$_; return ;;
      ( * ) ;;
    esac
  done
}

userscripts::preproc::_writefile ()
{
: private-prefix _us_pp
  _us_pp_process_loop > "$us_pp_output"
}

# Id: us-pp         vim:set ft=bash sw=2 sts=2 et:
