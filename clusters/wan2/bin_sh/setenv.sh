#
# Add cluster specific environment variables in this file.
#

# The 'padolite.enabled' property in 'etc/cluster.properties' enables
# PadoLite in cluster members.
PADOLITE_ENABLED=$(getClusterProperty "padolite.enabled" "false")

# The 'spring.bootstrap.enabled' property in 'etc/cluster.properties'
# enables bootstrapping cache servers using Spring.
SPRING_BOOTSTRAP_ENABLED=$(getClusterProperty "spring.bootstrap.enabled" "false")
if [ "$SPRING_BOOTSTRAP_ENABLED" == "true" ]; then
   if [ "$PADOLITE_ENABLED" == "true" ]; then
      CONFIG_FILE=$ETC_DIR/cache-spring-padolite.xml
   else
      CONFIG_FILE=$ETC_DIR/cache-spring.xml
   fi
   JAVA_OPTS="$JAVA_OPTS --J=-Dgeode-addon.application.context.file=application-context.xml"
   CLASSPATH=$CLASSPATH:$ETC_DIR/
fi

# Enable Pado if defined in setenv_pado.sh
if [ -f $CLUSTER_DIR/pado/bin_sh/setenv_pado.sh ]; then
   . $CLUSTER_DIR/pado/bin_sh/setenv_pado.sh
fi

#
# Set Java options, i.e., --J=-Dproperty=xyz
#
#JAVA_OPTS=

MEMBER_NUMBER=$MEMBER_NUM_NO_LEADING_ZERO
if [ "$VM_ENABLED" == "true" ]; then
   MEMBER=`getVmMemberName`
else
   MEMBER=`getMemberName $MEMBER_NUMBER`
fi

# Create disk store dirs if in the cluster context
if [ "$CLUSTER_DIR" != "" ]; then
   SERVER_GROUP="wan-serversj"
   DISKSTORE=$CLUSTER_DIR/store
   SERVER_NAME="$MEMBER"
   BUCKETS=113

   JAVA_OPTS="$JAVA_OPTS --J=-DSERVER_GROUP=$SERVER_GROUP"
   JAVA_OPTS="$JAVA_OPTS --J=-DDISKSTORE=$DISKSTORE"
   JAVA_OPTS="$JAVA_OPTS --J=-DSERVER_NAME=$SERVER_NAME"
   JAVA_OPTS="$JAVA_OPTS --J=-DBUCKETS=$BUCKETS"

   # Create disk store directories if not exist
   DISKSTORE_DIR_NAMES="wan pdx pbm nw"
   __IFS=$IFS
   IFS=" "
   for NAME in $DISKSTORE_DIR_NAMES; do
      if [ ! -d ${DISKSTORE}/$NAME/${SERVER_NAME} ]; then
        echo "mkdir -p \"${DISKSTORE}/$NAME/${SERVER_NAME}\""
        mkdir -p "${DISKSTORE}/$NAME/${SERVER_NAME}"
      fi
   done
   IFS=$__IFS
fi

#
# Some useful Geode/GemFire system properties:
#
# Always keep values serialized. By default, once deserialized it remains deserialized. Default: false 
#JAVA_OPTS=$JAVA_OPTS --J=-Dgemfire.PREFER_SERIALIZED=true
#
# Enable invocation of listeners in both primary and secondary buckets. Default: false
#JAVA_OPTS=$JAVA_OPTS --J=-Dgemfire.BucketRegion.alwaysFireLocalListeners=true

# IMPORTANT:
#    If you are running on Windows, then you must convert the file paths from Unix notations
#    Windows notations. For example,
# HIBERNATE_CONFIG_FILE="$CLUSTER_DIR/etc/hibernate.cfg-mysql.xml"
# if [[ ${OS_NAME} == CYGWIN* ]]; then
#    HIBERNATE_CONFIG_FILE="$(cygpath -wp "$HIBERNATE_CONFIG_FILE")"
# fi
# JAVA_OPTS="$JAVA_OPTS --J=-Dgeode-addon.hibernate.config=$HIBERNATE_CONFIG_FILE"

# To use Hibernate backed CacheWriterLoaderPkDbImpl, set the following property and
# configure CacheWriterLoaderPkDbImpl in the $CLUSTER_DIR/etc/cache.xml file.
# MySQL and PostgreSQL Hibernate configuration files are provided to get
# you started. You should copy one of them and enter your DB information.
# You can include your JDBC driver in the ../pom.xml file and run ./build_app
# which downloads and places it in the $PADOGRID_WORKSPACE/lib
# directory. CLASSPATH includes all the jar files in that directory for
# the apps and clusters running in this workspace.
#
#JAVA_OPTS="$JAVA_OPTS --J=-Dgeode-addon.hibernate.config=$CLUSTER_DIR/etc/hibernate.cfg-mysql.xml"
#JAVA_OPTS="$JAVA_OPTS --J=-Dgeode-addon.hibernate.config=$CLUSTER_DIR/etc/hibernate.cfg-postgresql.xml"
#JAVA_OPTS="$JAVA_OPTS --J=-Dgeode-addon.hibernate.config=$CLUSTER_DIR/etc/hibernate.cfg-derby.xml"

#
# Set RUN_SCRIPT. Absolute path required.
# If set, the 'start_member' command will run this script instead of 'gfsh start server'.
# Your run script will inherit the following:
#    JAVA              - Java executable.
#    JAVA_OPTS         - Java options set by padogrid.
#    LOCATOR_JAVA_OPTS - Locator specific Java options.
#    MEMBER_JAVA_OPTS  - Locator specific Java options.
#    CLASSPATH         - Class path set by padogrid. You can include additional libary paths.
#                        You should, however, place your library files in the plugins
#                        directories if possible.
#  CLUSTER_DIR - This cluster's top directory path, i.e., /opt/padogrid/workspaces/myrwe/padogrid-grafana/clusters/wan2
#
# Run Script Example:
#    "$JAVA" $JAVA_OPTS com.newco.MyMember &
#
# Although it is not required, your script should be placed in the bin_sh directory.
#
#RUN_SCRIPT=$CLUSTER_DIR/bin_sh/your-script
