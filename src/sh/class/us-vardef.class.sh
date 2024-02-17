us_vardef_class__load ()
{
  declare -gA us_vardef__var
}

class_Us_Vardef__load ()
{
  us_class_declare Us/Vardef ParameterizedClass --hooks vars
}

class_Us_Vardef_ ()
{
  case "${call:?}" in

      --vars )
          for vn
          do
            declare "us_vardef__var[$vn]=${static_class:?}"
          done
        ;;

    ( * ) return ${_E_next:?}
  esac && return ${_E_done:?}
}
