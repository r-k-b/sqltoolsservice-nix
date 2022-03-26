#!/usr/bin/env bash

set -eou pipefail

# standardize build-breaking case mismatches inside files (except this file)
# For example, it should convert both `pt-br` and `pt-Br` to `pt-BR`.
# See also: https://github.com/microsoft/sqltoolsservice/issues/886

ag -l 'pt-br' --hidden -u | grep -v 'standardizeCase.sh' | xargs -I FILE sed -i -e 's/pt-br/pt-BR/gI' FILE
ag -l 'zh-hans' --hidden -u | grep -v 'standardizeCase.sh' | xargs -I FILE sed -i -e 's/zh-hans/zh-Hans/gI' FILE
ag -l 'zh-hant' --hidden -u | grep -v 'standardizeCase.sh' | xargs -I FILE sed -i -e 's/zh-hant/zh-Hant/gI' FILE

# standardize build-breaking filename casing

find . -depth -iname '*pt-br*' -execdir sh -c '
  x=$(echo {} | sed s/pt-br/pt-BR/gI)
  if [ "{}" == "$x" ]; then
    echo skipping {}
  else
    echo moving {} to $x
    mv {} $x
  fi;
' \;
find . -depth -iname '*zh-hans*' -execdir sh -c '
  x=$(echo {} | sed s/zh-hans/zh-Hans/gI)
  if [ "{}" == "$x" ]; then
    echo skipping {}
  else
    echo moving {} to $x
    mv {} $x
  fi;
' \;
find . -depth -iname '*zh-hant*' -execdir sh -c '
  x=$(echo {} | sed s/zh-hant/zh-Hant/gI)
  if [ "{}" == "$x" ]; then
    echo skipping {}
  else
    echo moving {} to $x
    mv {} $x
  fi;
' \;


# stop dotnet from failing the build due to missing destinations
mkdir -p bin/Debug/net6.0/zh-Hans
mkdir -p bin/Debug/net6.0/zh-Hant


# build still failing? you might also need to clear the nuget cache(s), as it
# seems that files with unexpected casing from previous builds can contaminate
# future builds.
# (e.g., `./bin/nuget/`, `~/.nuget/packages`, `~/.local/share/NuGet/cache`)


# prevent SRGen from breaking the build with the error:
#    An error occurred when executing task 'SRGen'.
#    Error: One or more errors occurred. (Object reference not set to an instance of an object)
#            Object reference not set to an instance of an object
rm src/Microsoft.SqlTools.ResourceProvider/Localization/sr.strings
