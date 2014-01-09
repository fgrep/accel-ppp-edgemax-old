#!/usr/bin/perl

use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::AccelPPPConfig;

my $PPPOE_INIT        = '/etc/init.d/accel-ppp';
my $FILE_PPPOE_CFG    = '/etc/accel-ppp/accel-ppp.conf';

my $config = new Vyatta::AccelPPPConfig;
my $oconfig = new Vyatta::AccelPPPConfig;
$config->setup();
$oconfig->setupOrig();

if (!($config->isDifferentFrom($oconfig))) {
    # config not changed. do nothing.
    exit 0;
}

if ($config->isEmpty()) {
    if (!$oconfig->isEmpty()) {
        system('/usr/sbin/invoke-rc.d accel-ppp stop');
        system("echo 'ACCEL_PPPD_OPTS=' > /etc/default/accel-ppp");
    }
    exit 0;
}

my ($pppoe_conf, $err) = (undef, undef);

#while (1) {
    ($pppoe_conf, $err) = $config->get_ppp_opts();
    last if (defined($err));
#}

if (defined($err)) {
    print STDERR "accel-ppp PPPoE server configuration error: $err.\n";
    exit 1;
}

exit 1 if (!$config->removeCfg($FILE_PPPOE_CFG));

exit 1 if (!$config->writeCfg($FILE_PPPOE_CFG, $pppoe_conf, 0, 0));

if ($config->needsRestart($oconfig)) {
    # restart pppoe-server
    # XXX need to kill all pptpd instances since it does not keep track of
    # existing sessions and will start assigning IPs already in use.
    system("echo 'ACCEL_PPPD_OPTS=\"-c /etc/accel-ppp/accel-ppp.conf\"' > /etc/default/accel-ppp");
    system('/usr/bin/accel-cmd shutdown >&/dev/null');
    my $rc = system('/usr/sbin/invoke-rc.d accel-ppp start');
    exit $rc;
}
exit 0;
