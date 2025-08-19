# Build custom image extending crowdsec to include (placeholder) appsec binary
FROM crowdsecurity/crowdsec:latest

# Placeholder: In future, replace with official appsec-enabled build once available.
# For now we just copy the main crowdsec binary as a stand-in so container doesn't crash.
RUN cp /usr/local/bin/crowdsec /usr/local/bin/appsec

ENTRYPOINT ["/usr/local/bin/appsec"]
CMD ["-c", "/etc/crowdsec/appsec/appsec.yaml"]
