use utf8;

Set($WebPort, RT_WEB_PORT);
Set($MailCommand, "testfile");
Plugin("RT::Authen::Token");
Plugin("RT::Extension::REST2");

1;
