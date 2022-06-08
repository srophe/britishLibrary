# Specify the eXist-db release as a base image
FROM existdb/existdb:6.0.1

COPY build/*.xar /exist/autodeploy/
COPY conf/controller-config.xml /exist/etc/webapp/WEB-INF/
COPY conf/exist-webapp-context.xml /exist/etc/jetty/webapps/
COPY conf/conf.xml /exist/etc

# Ports
EXPOSE 8080 8444

ARG ADMIN_PASSWORD
ENV ADMIN_PASSWORD=$ADMIN_PASSWORD

# Start eXist-db
CMD [ "java", "-jar", "start.jar", "jetty" ]
RUN [ "java", "org.exist.start.Main", "client", "--no-gui",  "-l", "-u", "admin", "-P", "", "-x", "sm:passwd('admin','$ADMIN_PASSWORD')" ]
