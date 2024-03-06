us_cache_class__load ()
{
  true
}

class_Us_Cache__load ()
{
  uc_class_declare Us/Cache Us/Vardef --hooks us-cache --vars keys
  #--globals std:cache
}

class_Us_Cache_ ()
{
  case "${call:?}" in

      --us-cache )
          local vk=$(class.Vardef --var keys)
        ;;

    ( * ) return ${_E_next:?}
  esac && return ${_E_done:?}
}
