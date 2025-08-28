#!/bin/bash

# Configure Postfix SMTP relay if explicitly enabled
if [ -n "${QUANT_SMTP_HOST:-}" ] && [ "${QUANT_SMTP_RELAY_ENABLED:-}" = "true" ]; then
    echo "Configuring Postfix SMTP relay with host: $QUANT_SMTP_HOST"
    
    # Configure domain from QUANT_SMTP_FROM_DOMAIN or extract from QUANT_SMTP_FROM
    if [ -n "$QUANT_SMTP_FROM_DOMAIN" ]; then
        DOMAIN="$QUANT_SMTP_FROM_DOMAIN"
    elif [ -n "$QUANT_SMTP_FROM" ]; then
        DOMAIN=$(echo "$QUANT_SMTP_FROM" | cut -d@ -f2)
    else
        DOMAIN="quantcdn.io"  # fallback
    fi
    
    POSTFIX_HOSTNAME="${QUANT_SMTP_HOSTNAME:-wordpress.$DOMAIN}"
    
    # Install Postfix if not already installed
    if ! command -v postconf >/dev/null 2>&1; then
        echo "Installing Postfix with SASL support..."
        # Pre-configure Postfix to avoid interactive prompts
        export DEBIAN_FRONTEND=noninteractive
        echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
        echo "postfix postfix/mailname string $POSTFIX_HOSTNAME" | debconf-set-selections
        apt-get update && apt-get install -y --no-install-recommends postfix ca-certificates libsasl2-modules
    fi
    postconf -e "myhostname=$POSTFIX_HOSTNAME"
    postconf -e "mydomain=$DOMAIN"
    postconf -e "myorigin=\$mydomain"
    postconf -e "inet_interfaces=127.0.0.1"
    postconf -e "inet_protocols=ipv4"
    postconf -e "mydestination="
    postconf -e "local_transport=error:local delivery disabled"
    postconf -e "relayhost=[$QUANT_SMTP_HOST]:$QUANT_SMTP_PORT"
    
    # Configure TLS per AWS SES documentation (using modern parameters)
    postconf -e "smtp_tls_security_level=encrypt"  # Replaces deprecated smtp_use_tls=yes
    postconf -e "smtp_tls_note_starttls_offer=yes"
    
    postconf -e "smtp_sasl_auth_enable=yes"
    postconf -e "smtp_sasl_security_options=noanonymous"
    postconf -e "smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt"
    
    # Create SASL password file
    echo "[$QUANT_SMTP_HOST]:$QUANT_SMTP_PORT $QUANT_SMTP_USERNAME:$QUANT_SMTP_PASSWORD" > /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
    
    # Initialize Postfix spool directories and permissions for container environment
    echo "Setting up Postfix spool directories..."
    
    # Create necessary spool directories
    mkdir -p /var/spool/postfix/{maildrop,incoming,active,deferred,bounce,defer,flush,hold,trace,corrupt}
    mkdir -p /var/spool/postfix/{private,public}
    mkdir -p /var/spool/postfix/etc
    
    # Set proper ownership and permissions that Postfix expects
    echo "Configuring Postfix spool directory ownership..."
    
    # Create postdrop group if it doesn't exist
    if ! getent group postdrop > /dev/null; then
        groupadd -r postdrop
    fi
    
    # Postfix expects specific ownership patterns:
    chown root:root /var/spool/postfix                       # Root directory must be root:root
    chown root:root /var/spool/postfix/etc                   # etc must be root:root  
    chown postfix:postfix /var/spool/postfix/private         # private is postfix:postfix
    chown postfix:postdrop /var/spool/postfix/public         # public must be postfix:postdrop
    chown postfix:postdrop /var/spool/postfix/maildrop       # maildrop must be postfix:postdrop
    
    # Set permissions
    chmod 755 /var/spool/postfix
    chmod 755 /var/spool/postfix/etc
    chmod 700 /var/spool/postfix/private
    chmod 755 /var/spool/postfix/public
    chmod 730 /var/spool/postfix/maildrop                    # Group writable for postdrop
    
    # Set ownership for other queue directories
    for dir in incoming active deferred bounce defer flush hold trace corrupt; do
        if [ -d "/var/spool/postfix/$dir" ]; then
            chown postfix:postfix "/var/spool/postfix/$dir"
            chmod 700 "/var/spool/postfix/$dir"
        fi
    done
    
    echo "Postfix spool directories configured with proper ownership"
    
    # Copy DNS files to Postfix chroot (needed for address resolution)
    cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf 2>/dev/null || true
    cp /etc/hosts /var/spool/postfix/etc/hosts 2>/dev/null || true
    
    # Start Postfix using the proper command (ensures all services start correctly)
    echo "Starting Postfix..."
    postfix start
    
    # Wait for Postfix to fully initialize all services
    sleep 4
    
    echo "Verifying Postfix startup..."
    
    # Check if master process is running
    if pgrep -f "/usr/lib/postfix/sbin/master" > /dev/null; then
        echo "✅ Postfix master process is running (PID: $(pgrep -f '/usr/lib/postfix/sbin/master'))"
    else
        echo "⚠️ Postfix master process not found"
    fi
    
    # Check if Postfix is listening on localhost:25
    sleep 1  # Give it another moment
    if netstat -ln 2>/dev/null | grep "127.0.0.1:25" > /dev/null || ss -ln 2>/dev/null | grep "127.0.0.1:25" > /dev/null; then
        echo "✅ Postfix is listening on 127.0.0.1:25"
    elif netstat -ln 2>/dev/null | grep ":25" > /dev/null || ss -ln 2>/dev/null | grep ":25" > /dev/null; then
        echo "✅ Postfix is listening on port 25 (any interface)"
        netstat -ln 2>/dev/null | grep ":25" || ss -ln 2>/dev/null | grep ":25"
    else
        echo "⚠️ Postfix not listening on port 25 yet - checking again in 2 seconds..."
        sleep 2
        if netstat -ln 2>/dev/null | grep ":25" > /dev/null || ss -ln 2>/dev/null | grep ":25" > /dev/null; then
            echo "✅ Postfix is now listening on port 25"
            netstat -ln 2>/dev/null | grep ":25" || ss -ln 2>/dev/null | grep ":25"
        else
            echo "❌ Postfix still not listening on port 25"
        fi
    fi
    
    # Test basic postfix commands
    if postconf mail_version > /dev/null 2>&1; then
        echo "✅ Postfix configuration is accessible (Version: $(postconf -d mail_version | cut -d= -f2 | tr -d ' '))"
    else
        echo "⚠️ Cannot access Postfix configuration"
    fi
    
    # Check if pickup socket exists (critical for postdrop to work)
    if [ -S /var/spool/postfix/public/pickup ]; then
        echo "✅ Postfix pickup socket is available"
    else
        echo "⚠️ Postfix pickup socket not found - waiting a bit more..."
        sleep 2
        if [ -S /var/spool/postfix/public/pickup ]; then
            echo "✅ Postfix pickup socket now available"
        else
            echo "❌ Postfix pickup socket still missing - postdrop may not work properly"
            echo "   Checking what services are running:"
            postfix status 2>/dev/null || echo "   postfix status command not available"
        fi
    fi
    
    echo "✅ Postfix SMTP relay configured and started"
fi