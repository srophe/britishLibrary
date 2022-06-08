# Specify the eXist-db release as a base image
FROM existdb/existdb:6.0.1

COPY . ./
# Copy Srophe required libraries/modules to autodeploy, include the srophe.xar and the srophe-data.xar
COPY autodeploy/*.xar /exist/autodeploy/
# OPTIONAL: Copy custom controller-config.xml to WEB-INF. This sets the root app to srophe.
COPY conf/controller-config.xml /exist/etc/webapp/WEB-INF/
# OPTIONAL: Copy custom jetty config to set context to '/'
# See: https://exist-open.markmail.org/message/gjp2po2ducmckvix?q=set+app+as+root+order:date-backward
COPY conf/exist-webapp-context.xml /exist/etc/jetty/webapps/
# OPTIONAL: changes to conf.xml 
COPY conf/conf.xml /exist/etc

# Ports
EXPOSE 8080 8444

ARG ADMIN_PASSWORD
ENV ADMIN_PASSWORD=$ADMIN_PASSWORD

# Start eXist-db
CMD [ "java", "-jar", "start.jar", "jetty" ]
RUN [ "java", "org.exist.start.Main", "client", "--no-gui",  "-l", "-u", "admin", "-P", "", "-x", "sm:passwd('admin','$ADMIN_PASSWORD')" ]
