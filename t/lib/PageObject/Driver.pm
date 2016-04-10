package PageObject::Driver;

use strict;
use warnings;


use Carp;
use Moose;
use Selenium::Remote::Driver;
use Selenium::Waiter qw(wait_until);
use Test::More;

extends 'Selenium::Remote::Driver';


has page => (is => 'rw', isa => 'PageObject');


# In order to estimate the number of running ajax requests, we need
# to patch the XMLHttpRequest object prototype: that way we can install
# an open() method which adds an event listener.

sub _monkeypatch_xml_http_prototype {
    my ($self) = @_;

    # my thanks go to
    # http://stackoverflow.com/questions/9267451/how-to-check-if-http-requests-are-open-in-browser

    $self->execute_script(qq(
(function() {
    var oldOpen = XMLHttpRequest.prototype.open;
    window.__SELENIUM_538268 = 0;
    XMLHttpRequest.prototype.open = function(method, url, async, user, pass) {
      window.__SELENIUM_538268++;
      this.addEventListener("readystatechange", function() {
          if(this.readyState == 4) {
            window.__SELENIUM_538268--;
          }
        }, false);
      oldOpen.call(this, method, url, async, user, pass);
    }
  })();
));

}


=head1 METHODS

=over

=item prepare_driver($driver)

Installs some hooks in the browser(window) owned by the driver
to allow better waiting for any page activity to complete.

=cut

sub BUILD {
    my ($self) = @_;
    &_monkeypatch_xml_http_prototype($self);
    $self->set_implicit_wait_timeout(30000); # 30s
    $self->set_window_size(1024, 1280);
}

sub find_element_by_label {
    my ($self, $label) = @_;

    my $label_element = $self->find_element("//label[text()='$label']");
    do {
        croak "no label with text '$label'";
        return;
    } unless defined $label_element;

    my $element_id = $label_element->get_attribute('for');
    do {
        croak "no 'for' attribute of element with label '$label'";
        return;
    } unless defined $element_id;

    my $element = $self->find_element("//*[\@id='$element_id']");
    do {
        croak "no element with label '$label' and id '$element_id' found";
        return;
    } unless defined $element;

    return $element;
}


=item find_button($self, $text)


=cut

sub find_button {
    my ($self, $text) = @_;

    my $btn = $self->find_element(
        "//span[text()='$text'
                and contains(concat(' ',normalize-space(\@class),' '),
                             ' dijitButtonText ')]
         | //button[text()='$text']
         | //input[\@value='$text'
                   and (\@type='submit' or \@type='image' or \@type='reset')]");
    ok($btn, "found button tag '$text'");

    return $btn;
}


=item find_dropdown($self, $text)


=cut

sub find_dropdown {
    my ($self, $label) = @_;

    my $elm = find_element_by_label($self,$label);
    ok(element_is_dropdown($elm),
       "Found drop down element '$label'");

    return $elm;
}

=item find_option($self, $text, $dropdown)


=cut


our $max_wait_secs = 10;
my $page_generation = 0;
sub try_wait_for_page {
    my ($self) = @_;

    wait_until { $self->find_element('body.done-parsing', 'css') };

    $page_generation++;
    $self->execute_script(qq(
if (dojo && require) {
  require(["dojo/ready"], function(ready) {
     ready(9999, function() { window.__SELENIUM_5382645 = $page_generation; })
  });
}
else {
   // detection failed
   window.__SELENIUM_5382645 = $page_generation;
}
));

    my $start_time = time();
    while (((time() - $start_time) < $max_wait_secs)
           && $self->execute_script(qq(
 return ((window.__SELENIUM_5382645 < $page_generation)
         || (window.__SELENIUM_538268 > 0))
       ))){
        sleep(0.05);
    };
}


sub find_elements_containing_text {
    my ($self, $text) = @_;


    return $self->find_elements(
        "//*[contains(.,'$text')]
            [not(.//*[contains(.,'$text')])]");
}


sub verify_page {
    my ($self) = @_;

    $self->try_wait_for_page;
    return $self->page->verify;
}

sub verify_screen {
    my ($self) = @_;

    $self->try_wait_for_page;
    $self->page->verify;
    return $self->page->maindiv->content;
}

__PACKAGE__->meta->make_immutable();


1;
