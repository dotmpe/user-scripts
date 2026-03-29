# Copyright 2026 hari <dev@dotmpe>
#
# Distributed under terms of the MIT license.

userscripts::preproc::_op_define ()
{
: private-prefix _us_pp

# TODO: use param for lang or other keys/attrs
  [[ ! ${current_param:+set} ]] ||
    failerr "Unexpected parameter(s) ${current_param@Q}" || return
  #us_pp_param["$current_dir"]=$current_param
  us_pp_defs["$current_dir"]=$current_block
  us_pp_def_literal["$current_dir"]=$current_literal
  ((QUIET)) || >&2 echo "Defined ${current_dir} = ${current_block@Q}"
}

userscripts::preproc::_op_generate ()
{
: private-prefix _us_pp
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
  case "$current_dir" in
  ( debug ) echo '#include <debug.sh.h>' ;;

  ( log ) [[ ${us_pp_lang} = bash ]] && {
          echo "export LOG=\$HOME/bin/tool/sh/log.sh"
          declare -f failerr userscripts::core::echo_stderr_with_status
          #declare -f failerr User-Script.Core.echo-stderr-with-status
        }
      ;;

  ( strict ) echo '#include <strict.sh.h>' ;;

  ( * )
      local -n _dir=current_dir
      local -n _def='us_pp_defs["$_dir"]'
      local -n _def_lit='us_pp_def_literal["$_dir"]'
      [[ ${_def:+set} ]] ||
        failerr "No such snippet or definition ${_dir@Q}" || return

      ((current_literal)) || {
        ((_def_lit)) || >&2 echo "Warn: Source is not literal ${_dir@Q}"
      }
      local _new="${_def//"{{$_dir.content}}"/"$current_param"}"
      ((_def_lit)) && echo -n "$_new" || _us_pp_unshift_lineblock _new

  esac
}

userscripts::preproc::_op_special ()
{
: private-prefix _us_pp
  case "$current_dir" in

  ( data )
      [[ ${current_param:+set} ]] ||
        failerr "Expected parameter(s) ${current_dir@Q}" || return
      local file rest
      read -r file rest <<< "$current_param"
      [[ ! ${rest:+set} ]] || failerr "Surplus parameter(s) ${rest@Q}" || return
      . "$file" ||
        failerr "E$? while loading ${file@Q}"
    ;;

  ( declare )
      [[ ${current_param:+set} ]] ||
        failerr "Expected parameter(s) ${current_dir@Q}" || return
      local -a args
      read -r -a args <<< "$current_param"
      # XXX: bash format
      #>&2 echo declare "${args[@]}"
      declare "${args[@]}"
    ;;

  ( include )
      [[ ${current_param:+set} ]] ||
        failerr "Expected parameter(s) ${current_dir@Q}" || return
      local name rest path ext
      read -r name rest <<< "$current_param"
      [[ ! ${rest:+set} ]] || failerr "Surplus parameter(s) ${rest@Q}" || return
      ! ((DEBUG)) || ((QUIET)) ||
        >&2 echo "Resolving $current_dir $name"
      for ext in .build "" .bash
      do path=$(command -v "$name$ext") && break
      done
      [[ -f "$path" ]] ||
        failerr "Unable to resolve ${name@Q}" || return
      _us_pp_unshift_source "$path"
    ;;

  ( license )
      [[ ! ${current_param:+set} ]] ||
        failerr "Unexpected parameter(s) ${current_param@Q}" || return
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

  ( modeline ) [[ ${us_pp_lang} = bash ]] && {
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

userscripts::preproc::_prepfile ()
{
: private-prefix _us_pp
  us_pp_input=${2}
  us_pp_shebang=$(head -n 1 "${2}")
  : "${us_pp_shebang##*/}"
  us_pp_lang=${_#* }
  us_pp_inputreal="$(realpath "${2}")"
  : "${us_pp_inputreal%/*}"
  : "${us_pp_inputreal##*/},${_//\//-}${1}"
  us_pp_output=/tmp/${_}
  _us_pp_run
}

userscripts::preproc::_process_loop () {
: private-prefix _us_pp
  _us_pp_open_filesource () {
    exec {new_fd}<"$1" ||
        failerr "E$? opening FD for file ${1@Q}" || return
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
    if ! IFS= read -r us_pp_line <&$us_pp_fd
    then
      #XXX: try: close
      exec {us_pp_fd}<&- &&
      unset ${!us_pp_fd} ||
        failerr "E$? closing FD $us_pp_fd" || return
      #/
      (( ${#us_pp_input_stack[*]} == 0 )) && return ${_E_break:?}
      return ${_E_next:?}
    fi
    ! ((DEBUG)) || ((QUIET)) ||
      >&2 echo "FD $us_pp_fd read line ${us_pp_line@Q}"
  }

  # Prepare to run different directives
#:declare -p us_pp_op
  local -A us_pp_op=(
    ['%']=define
    ['<']=template
    ['>']=generate
    ['&']=snippet
    [':']=special
  )
  local -A us_pp_{defs,def_literal}
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
  us_pp_input_stack=( "$new_fd" )
  # Main processing loop: read one line at a time, from last FD on stack until
  # all inputs are read
  while true
  do
    _us_pp_readline || {
      test $_E_next -eq $? && continue || {
        test $_E_break -eq $_ && break || return $_
      }
    }
    if case "$us_pp_line" in
    ( \#[\&:]* )
        current_op=${us_pp_line:1:1}
        read -r current_dir current_param <<< "${us_pp_line:2}"
        [[ ${current_dir:0:1} == "'" ]] &&
        current_dir=${current_dir:1:-1} current_literal=1 ||
          current_literal=0
      ;;
    ( \#[\<\>%]* )
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
              failerr "EOF while reading $current_dir block" || return
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
    ( '#!'* )
      #echo "$us_pp_shebang"
      echo "#!/usr/bin/env $us_pp_lang"
      continue ;;
    ( '##'* ) false ;;
    ( '#'* ) continue ;;
    ( * ) false ;;
    esac; then
      #declare -p current_{dir,param,op,block,literal}
      _us_pp_op_${_op} || {
        test $_E_next -eq $? || return $_
      }
      unset current_{block,dir,literal,op,param}
      continue
    fi

    echo "$us_pp_line"
  done
}

userscripts::preproc::_procfile ()
{
: private-prefix _us_pp
  us_pp_input=${1}
  us_pp_shebang=$(head -n 1 "$1")
  : "${us_pp_shebang##*/}"
  us_pp_alias=${_#* }
  us_pp_lang=${us_pp_alias#*.}
  us_pp_inputreal="$(realpath "${1}")"
  : "${us_pp_inputreal%/*}"
  : "${us_pp_inputreal##*/},${_//\//-}.mpe"
  us_pp_output=/tmp/${_}
  _us_pp_run
}

userscripts::preproc::_run ()
{
: private-prefix _us_pp
  ((QUIET)) || >&2 echo "$$ us-pp: reading: $us_pp_input"
  _us_pp_writefile || return
  ((QUIET)) || >&2 echo "$$ us-pp: done: $us_pp_output"
}

userscripts::preproc::_writefile ()
{
: private-prefix _us_pp
  _us_pp_process_loop > "$us_pp_output"
}

# Id: us-pp         vim:set ft=bash sw=2 sts=2 et:
