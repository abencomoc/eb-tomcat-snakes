# ---- Stage 1: Build ----
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS builder

RUN dnf update -y && \
    dnf install -y java-17-amazon-corretto-devel maven findutils tar gzip && \
    dnf clean all

WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline -B -q

COPY src/ src/

# Remove any pre-existing JARs in WEB-INF/lib to avoid duplicates with Maven dependencies
RUN rm -rf src/WEB-INF/lib

RUN mvn package -DskipTests -B -T 1C

# ---- Stage 2: Runtime ----
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf update -y && \
    dnf install -y java-17-amazon-corretto findutils tar gzip shadow-utils && \
    dnf clean all

# Create user and group with UID/GID 10000
RUN groupadd -r -g 10000 appuser && \
    useradd -r -u 10000 -g appuser appuser

# Install Tomcat 9
ENV CATALINA_HOME=/opt/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

RUN TOMCAT_VERSION=$(curl -fSL "https://dlcdn.apache.org/tomcat/tomcat-9/" | grep -oP 'v9\.\d+\.\d+' | sort -V | tail -1) && \
    curl -fSL "https://dlcdn.apache.org/tomcat/tomcat-9/${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION#v}.tar.gz" -o /tmp/tomcat.tar.gz && \
    mkdir -p "$CATALINA_HOME" && \
    tar -xzf /tmp/tomcat.tar.gz -C "$CATALINA_HOME" --strip-components=1 && \
    rm /tmp/tomcat.tar.gz && \
    rm -rf "$CATALINA_HOME/webapps/ROOT" \
           "$CATALINA_HOME/webapps/examples" \
           "$CATALINA_HOME/webapps/docs" \
           "$CATALINA_HOME/webapps/host-manager" \
           "$CATALINA_HOME/webapps/manager"

# Copy the WAR from the builder stage
COPY --from=builder /build/target/ROOT.war $CATALINA_HOME/webapps/ROOT.war

# Set ownership so appuser (10000) can run Tomcat
RUN chown -R appuser:appuser "$CATALINA_HOME"

USER 10000

EXPOSE 8080

CMD ["catalina.sh", "run"]
