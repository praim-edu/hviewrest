FROM microsoft/powershell:ubuntu16.04
ARG SERVER
ARG USER
ARG PASSWORD
ARG DOMAIN

LABEL authors="jacopoferraro@praim.com,michele.bridi@marconirovereto.it,mauro.slomp@marconirovereto.it"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y unzip && apt-get clean

# Set working directory so stuff doesn't end up in /
WORKDIR /root

# Install VMware modules from PSGallery
SHELL [ "pwsh", "-command" ]
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
RUN Install-Module VMware.PowerCLI,PowerNSX,PowervRA

# Add the PowerCLI Example Scripts and Modules
# using ZIP instead of a git pull to save at least 100MB
SHELL [ "bash", "-c"]
RUN curl -o ./PowerCLI-Example-Scripts.zip -J -L https://github.com/vmware/PowerCLI-Example-Scripts/archive/master.zip && \
    unzip PowerCLI-Example-Scripts.zip && \
    rm -f PowerCLI-Example-Scripts.zip && \
    mv ./PowerCLI-Example-Scripts-master ./PowerCLI-Example-Scripts && \
    mv ./PowerCLI-Example-Scripts/Modules/* /usr/local/share/powershell/Modules/ && \
    curl -o ./hviewrestsvc.ps1 -J -L https://raw.githubusercontent.com/praim-edu/hviewrest/master/hviewrestsvc.ps1

EXPOSE 8000

RUN echo SERVER is $SERVER
RUN echo DOMAIN is $DOMAIN
RUN echo USER is $USER

ENTRYPOINT ["/usr/bin/pwsh", "hviewrestsvc.ps1", "$SERVER", "$USER", "$PASSWORD", "$DOMAIN"]
