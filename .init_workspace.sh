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

ERROR_OCCURED="false"
if [ "$WORKSPACE" == "" ]; then
   echo >&2 "ERROR: Workspace not specified. The first argument must be the target workspace name. Command aborted."
   ERROR_OCCURED="true"
fi
if [ ! -d "$WORKSPACE_PATH" ]; then
   echo >&2 "ERROR: Specified workspace does not exist [$WORKSPACE_NAME]. Command aborted."
   ERROR_OCCURED="true"
fi

if [ "$ERROR_OCCURED" == "false" ]; then
   FOUND="false"
   WORKSPACES=$(list_workspaces)
   for i in $WORKSPACES; do
      if [ "$i" == "$WORKSPACE" ]; then
         FOUND="true"
      fi
   done

   if [ "$FOUND" == "false" ]; then
      echo >&2 "ERROR: Specified workspace not found in the current RWE [$WORKSPACE]. Command aborted."
      ERROR_OCCURED="true"
   fi
fi

if [ "$ERROR_OCCURED" == "false" ]; then
   # Switch workspace. This is required in order to build the bundle environment.
   switch_workspace $WORKSPACE_NAME

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

   #
   # Add 1 locator and 3 members to each cluster
   #
   clusters="mygemfire1 mygemfire2 mygemfire3 wan1, wan2"
   for i in $clusters; do
      locator_count=$(show_cluster -no-color -cluster $i | grep "Locators Running" | awk '{print $3}' | sed 's/^.*\///')
      count=$((1 - $locator_count))
      if [ $count -gt 0 ]; then
         add_locator -cluster $i -count $count
      fi
      member_count=$(show_cluster -no-color -cluster $i | grep "Members Running" | awk '{print $3}' | sed 's/^.*\///')
      count=$((3 - $member_count))
      if [ $count -gt 0 ]; then
         add_member -cluster $i -count $count
      fi
   done

   # Create grafana app and update it with the repo contents
   cd_app
   mv grafana grafana_org
   create_app -product gemfire -app grafana
   cp -rf grafana_org/* grafana/
   rm -rf grafana_org

   # Update host name to Prometheus config files
   pushd $WORKSPACE_PATH/apps/grafana/etc > /dev/null
   # Copy all configuration files to etc.
   cp config_templates/* .
   # Update the host address
   sed -i "s/HOST-ADDRESS/`hostname`/g" *.yml
   popd > /dev/null

   # Build perf_test app - downloads required binaries
   cd_app perf_test/bin_sh
   ./build_app

   echo ""
   echo "Bundle workspace initialization complete [$WORKSPACE]."
   echo ""
fi
