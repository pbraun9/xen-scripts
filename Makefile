
install:
        install -d $(DESTDIR)$(PREFIX)/sbin/

        install -m 755 dnc-consoleguest.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-new-resource-template.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-new-resource.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-newguest-debian.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-newguest-netbsd.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-newguest-slack.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-rebootguest.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-remove-resource.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-running-guest.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-running-guests.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-running-vrrp.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-shutdown-guest.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-startguest-lowram.bash $(DESTDIR)$(PREFIX)/sbin/
        install -m 755 dnc-startguest.bash $(DESTDIR)$(PREFIX)/sbin/

