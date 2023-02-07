# Citrix Download Helper
FROM fedora:latest AS citrix

RUN dnf install -y wget libxml2 unzip

# Downlaod Citrix RPM Package
## Get Download Page
RUN wget https://www.citrix.com/downloads/workspace-app/linux/workspace-app-for-linux-latest.html -O fucitrix.html 

## Extract authorized Download URL for latest Package
RUN echo 'cat //html/body/div[2]/div/div[2]/div[2]/div/div[3]/div/div[1]/div/div[4]/div/div/div[3]/div[2]/div/div/div/div/div/div[2]/div[2]/div/div/div[1]/div/div/div/div/a/@rel' | xmllint --html --shell fucitrix.html 2>/dev/null | grep rel | cut -d\" -f2 | sed -e 's/^/https:/' | xargs wget -O citrix.rpm 

## Delete Download Page
RUN rm fucitrix.html

FROM quay.io/rh_ee_bgrossew/firefox:latest

#Install Dependencies
RUN dnf install -y \
# ICAClient dependencies
    gtk2 \
    libXt \
    libXmu \
    libSM \
    libXpm \
    libICE \
    webkit2gtk4.0 \
    speexdsp \
# Routing
    iproute \
    net-tools 

# Install Ctrix Workspace
RUN mkdir -p /tmp/packages

# Get Citrix Workspace RPM
COPY --from=citrix citrix.rpm /tmp/packages/citrix.rpm

# Install Citrix Workspace
RUN rpm -i /tmp/packages/citrix.rpm

# Install Certificates into Citrix Workspace
RUN \
    if [ -d /mnt/certs ]; then \
        cp /mnt/certs/* /opt/Citrix/ICAClient/keystore/cacerts/
        /opt/Citrix/ICAClient/util/ctx_rehash
    fi

# Install Certificates for System
RUN \
    if [ -d /mnt/trustanchors ]; then \
        cp -r /mnt/trustanchors /tmp/trust \
        cp /tmp/trust/* /etc/pki/ca-trust/source/anchors/ \
        update-ca-trust; \
    fi

# Create Firefox Policy
ARG HOMEPAGES=https://www.redhat.com
ARG POLICY=/usr/lib64/firefox/distribution/policies.json

RUN \
    IFS=' ' read -ra pages <<< "$HOMEPAGES" && \
    echo -e '{'                                                               > $POLICY && \
    echo -e '    "policies": {'                                              >> $POLICY && \
                     #Suppress FirstStart Page
    echo -e '        "OverrideFirstRunPage" : "",'                           >> $POLICY && \
                     #Set Start Pages
    echo -e '        "Homepage": {'                                          >> $POLICY && \
    echo -e '            "URL": "'${pages[0]}'",'                            >> $POLICY && \
    echo -e '            "Locked": true,'                                    >> $POLICY && \
    echo -e '            "Additional": ['                                    >> $POLICY && \

    if [ ${#pages[@]} -gt 1 ]; then  \
        ind=$(printf ' %.0s' {1..16}) \
        ADD=$(for p in ${pages[@]:1:${#pages}-1}; do echo "$ind\"${p}\","; done) && \
        (IFS=$"\n"; echo -e ${ADD:0:${#ADD}-1})                              >> $POLICY; \
    fi && \

    echo -e '            ],'                                                 >> $POLICY && \
    echo -e '            "StartPage": "homepage"'                            >> $POLICY && \
    echo -e '        },'                                                     >> $POLICY && \
                     #Install additional Certificates
    echo -e '        "Certificates": {'                                      >> $POLICY && \
    echo -e '            "Install": ['                                       >> $POLICY && \

    if [ -d /tmp/trust ]; then  \
        ind=$(printf ' %.0s' {1..16}) \
        CERTS=$(for f in /tmp/trust/*; do echo "$ind\"$f\","; done) && \
        (IFS=$"\n"; echo -e ${CERTS:0:${#CERTS}-1})                          >> $POLICY; \
    fi && \

    echo -e '            ]'                                                  >> $POLICY && \
    echo -e '        }'                                                      >> $POLICY && \
    echo -e '    }'                                                          >> $POLICY && \
    echo -e '}'                                                              >> $POLICY

#Configure Entrypoint 
COPY entrypoint.sh /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]

#Example 'podman build' Command
#podman build . -t citrix  -v ~/certs:/mnt/certs:ro,z -v ~/trustanchors:/mnt/trustanchors:ro,z --build-arg HOMEPAGES="https://www.redhat.com https://www.google.com"

#Example 'podman run' Command
#  podman run -it --rm -v $XAUTHORITY:$XAUTHORITY:ro -v /tmp/.X11-unix:/tmp/.X11-unix:ro --userns keep-id --workdir=/tmp -e "DISPLAY" --network=host --ip 10.89.0.3 --dns 10.89.0.2 --ipc=host --cap-add=NET_ADMIN --security-opt label=type:container_runtime_t citrix





