#!/bin/bash
ES_HOME='/usr/share/elasticsearch'

[ ! -d "${ES_HOME}" ] && echo "directory ${ES_HOME} does not exist!" > /dev/stderr && exit

lib_dir="${ES_HOME}/lib"

elasticsearch_core_jar_name=$(/bin/ls ${lib_dir} | grep -E '^elasticsearch-core.*\.jar$')
[ $? -ne 0 ] && echo "could not found elasticsearch-x.x.x.jar in ${lib_dir}" && exit 1

elasticsearch_x_content_jar_name=$(/bin/ls ${lib_dir} | grep -E '^elasticsearch-x-content-.*\.jar$')
[ $? -ne 0 ] && echo "could not found  elasticsearch-x-content-x.x.x.jar in ${lib_dir}" && exit 1

lucene_core_jar_name=$(/bin/ls ${lib_dir} | grep -E '^lucene-core-.*\.jar$')
[ $? -ne 0 ] && echo "could not found lucene-core-x.x.x.jar in ${lib_dir}" && exit 1

#elasticsearch_core_jar_name=$(/bin/ls ) /usr/share/elasticsearch/lib

xpack_jar_base_dir="${ES_HOME}/modules/x-pack-core"
xpack_jar_name=$(/bin/ls ${xpack_jar_base_dir} | grep -E '^x-pack-.*\.jar$')
[ $? -ne 0 ] && echo "could not found x-pack-x.x.x.jar in ${xpack_jar_base_dir}" && exit 1

base_dir=$(mktemp -d --tmpdir $(basename $0).XXXXXXXX)
cd ${base_dir}

source_java_prefix='LicenseVerifier'
cat > ${source_java_prefix}.java << EOF_License
package org.elasticsearch.license;

public class LicenseVerifier
{
    public static boolean verifyLicense(final License license, final byte[] encryptedPublicKeyData) {
        return true;
    }
    
    public static boolean verifyLicense(final License license) {
        return true;
    }
}
EOF_License

source_java_xpackbuild='XPackBuild'
cat > ${source_java_xpackbuild}.java << EOF_License

package org.elasticsearch.xpack.core;
import org.elasticsearch.common.io.*;
import java.net.*;
import org.elasticsearch.common.*;
import java.nio.file.*;
import java.io.*;
import java.util.jar.*;
public class XPackBuild
{
    public static final XPackBuild CURRENT;
    private String shortHash;
    private String date;
    @SuppressForbidden(reason = "looks up path of xpack.jar directly")
    static Path getElasticsearchCodebase() {
        final URL url = XPackBuild.class.getProtectionDomain().getCodeSource().getLocation();
        try {
            return PathUtils.get(url.toURI());
        }
        catch (URISyntaxException bogus) {
            throw new RuntimeException(bogus);
        }
    }
    XPackBuild(final String shortHash, final String date) {
        this.shortHash = shortHash;
        this.date = date;
    }
    public String shortHash() {
        return this.shortHash;
    }
    public String date() {
        return this.date;
    }
    static {
        final Path path = getElasticsearchCodebase();
        String shortHash = null;
        String date = null;
        Label_0157: {
            shortHash = "Unknown";
            date = "Unknown";
        }
        CURRENT = new XPackBuild(shortHash, date);
    }
}

EOF_License

javac -cp "${lib_dir}/${elasticsearch_jar_name}:${lib_dir}/${lucene_core_jar_name}:${xpack_jar_base_dir}/${xpack_jar_name}" ${source_java_prefix}.java
javac -cp "${lib_dir}/${elasticsearch_jar_name}:${lib_dir}/${elasticsearch_core_jar_name}:/${lib_dir}/${elasticsearch_x_content_jar_name}: ${lib_dir}/${lucene_core_jar_name}:${xpack_jar_base_dir}/${xpack_jar_name}" ${source_java_xpackbuild}.java

mkdir xpack
cd xpack
jar -xf ${xpack_jar_base_dir}/${xpack_jar_name}
/bin/cp ../${source_java_prefix}.class org/elasticsearch/license/
#/bin/cp ../../XPackBuild.class org/elasticsearch/xpack/core/
/bin/cp ../${source_java_xpackbuild}.class org/elasticsearch/xpack/core/
jar -cf /tmp/${xpack_jar_name}.crack *
cat > /tmp/xpack_license.json << EOF_xpack_json
{"license":{"uid":"a122316a-1e06-4f91-9534-8d8418b97b1b","type":"platinum","issue_date_in_millis":1515628800000,"expiry_date_in_millis":2831215737000,"max_nodes":1000,"issued_to":"Roc Shen (Roc)","issuer":"Web Form","signature":"AAAAAwAAAA17GxIYIuMJmQjY1FP9AAABmC9ZN0hjZDBGYnVyRXpCOW5Bb3FjZDAxOWpSbTVoMVZwUzRxVk1PSmkxaktJRVl5MUYvUWh3bHZVUTllbXNPbzBUemtnbWpBbmlWRmRZb25KNFlBR2x0TXc2K2p1Y1VtMG1UQU9TRGZVSGRwaEJGUjE3bXd3LzRqZ05iLzRteWFNekdxRGpIYlFwYkJiNUs0U1hTVlJKNVlXekMrSlVUdFIvV0FNeWdOYnlESDc3MWhlY3hSQmdKSjJ2ZTcvYlBFOHhPQlV3ZHdDQ0tHcG5uOElCaDJ4K1hob29xSG85N0kvTWV3THhlQk9NL01VMFRjNDZpZEVXeUtUMXIyMlIveFpJUkk2WUdveEZaME9XWitGUi9WNTZVQW1FMG1DenhZU0ZmeXlZakVEMjZFT2NvOWxpZGlqVmlHNC8rWVVUYzMwRGVySHpIdURzKzFiRDl4TmM1TUp2VTBOUlJZUlAyV0ZVL2kvVk10L0NsbXNFYVZwT3NSU082dFNNa2prQ0ZsclZ4NTltbU1CVE5lR09Bck93V2J1Y3c9PQAAAQCX+UD6bN8Y30VOr7KRBPPIpZ6487L6HHl4p0KtTlc9+zb50v22VhL+WuAbJbV0ZA7I5bUSBBqFIYgqbx1Wi/egaZ+TbY0wz8uaKvL6DICVZ/Ec1OBE6U/1aRQWASOhZ9aQZ2GynxwTNut8Q9YkbyvEhlevxpX/ZUMmDafG7P3CeslqTI07gx6zZj9zyDFB/S6I/WonpZZgjftDViSqhNTDgwOLZd8otpNxU1Ws162Eb2wafCxeRWMl6DaQJW1v4sLtnvIzzVh6rZsSaGdJsq/BqVOnoUrDHO9HPUS6zt8wCZch4c86dSMyEJ7TjNlP9FZ9JYiPaXw6yG2FbSFhBJpM","start_date_in_millis":1515628800000}}
EOF_xpack_json

cat << EOF
*********************************************************************************************
xpack crack file: /tmp/${xpack_jar_name}.crack     md5:$(md5sum /tmp/${xpack_jar_name}.crack | awk '{print $1}')
license file: /tmp/xpack_license.json        md5:$(md5sum /tmp/xpack_license.json | awk '{print $1}')
*********************************************************************************************
EOF

#/bin/rm -rf ${base_dir}
