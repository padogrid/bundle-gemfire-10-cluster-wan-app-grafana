#!/usr/bin/env bash

#
# .init_workspace.sh
#
# This script is invoked by 'install_bundle -init -checkout' and 'install_bundle -init -download'
# immediately after the bundle has been installed.
#
# The first argument is always the workspace name in which the bundle is installed.
#

WORKSPACE_NAME="$1"
WORKSPACE_PATH="$PADOGRID_WORKSPACES_HOME/$WORKSPACE_NAME"

if [ "$WORKSPACE_NAME" == "" ]; then
   echo >&2 "ERROR: The first argument must be a valid workspace name. Command aborted."
   exit 1
fi
if [ ! -d "$WORKSPACE_PATH" ]; then
   echo >&2 "ERROR: Specified workspace does not exist [$WORKSPACE_NAME]. Command aborted."
   exit 2
fi

# The following fixes the bug that installs clusters with PRODUCT=none (since PadoGrid 1.0.1).
RWE_NAME=$(pwd_rwe)
mkdir -p ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/mygemfire1
mkdir -p ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/mygemfire2
mkdir -p ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/mygemfire3
mkdir -p ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/wan1
mkdir -p ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/wan2
cp $WORKSPACE_PATH/clusters/mygemfire1/.cluster/clusterenv.sh ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/mygemfire1/
cp $WORKSPACE_PATH/clusters/mygemfire1/.cluster/clusterenv.sh ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/mygemfire2/
cp $WORKSPACE_PATH/clusters/mygemfire1/.cluster/clusterenv.sh ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/mygemfire3/
cp $WORKSPACE_PATH/clusters/mygemfire1/.cluster/clusterenv.sh ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/wan1/
cp $WORKSPACE_PATH/clusters/mygemfire1/.cluster/clusterenv.sh ~/.padogrid/workspaces/$RWE_NAME/$WORKSPACE_NAME/clusters/wan2/

# Switch workspace. This is required in order to build the bundle environment.
switch_workspace $WORKSPACE_NAME

# Add members to clusters
add_locator -cluster mygemfire1
add_locator -cluster mygemfire2
add_locator -cluster mygemfire3
add_member -cluster mygemfire1 -count 2
add_member -cluster mygemfire2 -count 2
add_member -cluster mygemfire3 -count 2
add_member -cluster wan1 -count 2
add_member -cluster wan2 -count 2

# Update host name to Prometheus config files
pushd $WORKSPACE_PATH/apps/grafana/etc > /dev/null
# Copy all configuration files to etc.
cp config_templates/* .
# Update the host address
sed -i "s/HOST-ADDRESS/`hostname`/g" *.yml
popd > /dev/null
