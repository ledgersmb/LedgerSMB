--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Data for Name: template; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO template VALUES (38, 'shipping_label', NULL, '<?lsmb FILTER latex ?>
\documentclass{scrartcl}
\usepackage[latin1]{inputenc}
\usepackage{tabularx}
\usepackage[paperheight=10.5cm, paperwidth=16.2cm,top=1cm,bottom=1.5cm,left=2cm,right=2cm]{geometry}
\begin{document}
<?lsmb IF shiptoaddress1 ?>
\noindent <?lsmb name ?>\\
<?lsmb shiptoaddress1 ?>\\
<?lsmb IF shiptoaddress2; shiptoaddress2 ?>\\ <?lsmb END ?>
<?lsmb- shiptocity ?>
<?lsmb IF shiptostate -?>
\hspace{-0.1cm}, <?lsmb shiptostate ?><?lsmb END ?> <?lsmb shiptozipcode ?>\\
<?lsmb shiptocountry ?>
<?lsmb ELSE ?>
\noindent <?lsmb name ?>\\
<?lsmb address1 ?> \\
<?lsmb- IF address2; address2 ?> \\<?lsmb END ?>
<?lsmb- city ?>
<?lsmb- IF state -?>, <?lsmb state ?> <?lsmb END ?> <?lsmb zipcode ?>\\
<?lsmb END ?>

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (39, 'packing_list', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

\newsavebox{\ftr}
\sbox{\ftr}{
  \parbox{\textwidth}{
  \tiny
   \rule[1.5em]{\textwidth}{0.5pt}
<?lsmb text(''Items returned are subject to a 10% restocking charge.'') ?>
<?lsmb text(''A return authorization must be obtained from [_1] before goods are returned. Returns must be shipped prepaid and properly insured. [_1] will not be responsible for damages during transit.'', company) ?>
  }
}

<?lsmb INCLUDE letterhead.tex ?>

% Breaking old pagebreak directive
%<?xlsmb pagebreak 65 27 37 ?>
%\end{tabularx}
%
%\newpage
%
%\markboth{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}
%
%\begin{tabularx}{\textwidth}{@{}rlXllrrl@{}}
%  \textbf{Item} & \textbf{Number} & \textbf{Description} & \textbf{Serial Number} & & \textbf{Qty} & \textbf{Ship} & \\
%<?xlsmb end pagebreak ?>


\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
\textbf{Ship To}} \hfill

\vspace{0.3cm}

\parbox[t]{.5\textwidth}{
  
<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate ?>
\hspace{-0.1cm}, <?lsmb shiptostate ?>
<?lsmb END ?>
<?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>
}
\parbox[t]{.5\textwidth}{
  <?lsmb shiptocontact ?>
  
  <?lsmb IF shiptophone ?>
  Tel: <?lsmb shiptophone ?>
  <?lsmb END ?>
  
  <?lsmb IF shiptofax ?>
  Fax: <?lsmb shiptofax ?>
  <?lsmb END ?>
  
  <?lsmb shiptoemail ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Packing List'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{7}{|X}|} \hline
  \textbf{<?lsmb text(''Invoice #'') ?>} & \textbf{<?lsmb text(''Order #'') ?>} 
  & \textbf{<?lsmb text(''Date'') ?>} & \textbf{<?lsmb text(''Contact'') ?>}
  <?lsmb IF warehouse ?>
  & \textbf{<?lsmb text(''Warehouse'') ?>}
  <?lsmb END ?>
  & \textbf{<?lsmb text(''Shipping Point'') ?>} 
  & \textbf{<?lsmb text(''Ship via'') ?>} \\ [0.5em]
  \hline
  
  <?lsmb invnumber ?> & <?lsmb ordnumber ?>
  <?lsmb IF shippingdate ?>
  & <?lsmb shippingdate ?>
  <?lsmb ELSE ?>
  & <?lsmb transdate ?>
  <?lsmb END ?>
  & <?lsmb employee ?>
  <?lsmb IF warehouse ?>
  & <?lsmb warehouse ?>
  <?lsmb END ?>
  & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}
  
\vspace{1cm}
  
\begin{longtable}{@{\extracolsep{\fill}}rllllrrl@{}}
  \textbf{<?lsmb text(''Item'') ?>} & \textbf{<?lsmb text(''Number'') ?>} 
  & \textbf{<?lsmb text(''Description'') ?>} 
  & \textbf{<?lsmb text(''Serial Number'') ?>} & 
  & \textbf{<?lsmb text(''Qty'') ?>} & \textbf{<?lsmb text(''Ship'') ?>} & \\

<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb runningnumber.${lc} ?> &
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb serialnumber.${lc} ?> &
  <?lsmb deliverydate.${lc} ?> &
  <?lsmb qty.${lc} ?> &
  <?lsmb ship.${lc} ?> &
  <?lsmb unit.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\parbox{\textwidth}{
\rule{\textwidth}{2pt}

\vspace{12pt}

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>

}

\vfill

\rule{\textwidth}{0.5pt}

\usebox{\ftr}

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (4, 'work_order', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Work Order'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>
    
    <th colspan=3>
      <h4 style="text-transform:uppercase">
	<?lsmb text(''Work Order'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
	<tr bgcolor=000000>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''To'') ?></th>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''Ship To'') ?>
          </th>
	</tr>

	<tr valign=top>
	  <td><?lsmb name ?>
	  <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
	  <br><?lsmb address2 ?>
	  <?lsmb END ?>
	  <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
          <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
          <br>
	  <?lsmb IF contact ?>
	  <br><?lsmb text(''Attn: [_1]'', contact) ?>
	  <?lsmb END ?>
	  <?lsmb IF customerphone ?>
	  <br><?lsmb text(''Tel: [_1]'', customerphone) ?>
	  <?lsmb END ?>
	  <?lsmb IF customerfax ?>
	  <br><?lsmb text(''Fax: [_1]'', customerfax) ?>
	  <?lsmb END ?>
	  <?lsmb IF email ?>
	  <br><?lsmb email ?>
	  <?lsmb END ?>
	  </td>

	  <td><?lsmb shiptoname ?>
	  <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
	  <br><?lsmb shiptoaddress2 ?>
	  <?lsmb END ?>
	  <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
          <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
	  <br><?lsmb shiptocountry ?>
	  <?lsmb END ?>
	  <br>
          <?lsmb IF shiptocontact ?>
          <br><?lsmb shiptocontact ?>
          <?lsmb END ?>
	  <?lsmb IF shiptophone ?>
	  <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
	  <?lsmb END ?>
	  <?lsmb IF shiptofax ?>
	  <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
	  <?lsmb END ?>
	  <?lsmb IF shiptoemail ?>
	  <br><?lsmb shiptoemail ?>
	  <?lsmb END ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width=100% border=1>
	<tr>
	  <th width=17% align=left nowrap><?lsmb text(''Order #'') ?></th>
	  <th width=17% align=left><?lsmb text(''Order Date'') ?></th>
	  <th width=17% align=left><?lsmb text(''Required by'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Salesperson'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Shipping Point'') ?></th>
	  <th width=15% align=left nowrap><?lsmb text(''Ship Via'') ?></th>
	</tr>

	<tr>
	  <td><?lsmb ordnumber ?></td>
	  <td><?lsmb orddate ?></td>
	  <td><?lsmb reqdate ?></td>
	  <td><?lsmb employee ?></td>
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
 
    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=right><font color=ffffff><?lsmb text(''Item'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Qty'') ?></th>
	  <th>&nbsp;</th>
           <th><font color=ffffff><?lsmb text(''Bin'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Serial #'') ?></th>
	</tr>

	<?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
          <td align=right><?lsmb runningnumber.${loop_count} ?>.</td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td><?lsmb unit.${loop_count} ?></td>
           <td><?lsmb bin.${loop_count} ?></td>
	  <td><?lsmb serialnumber.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

	<tr>
	  <td colspan=7><hr noshade></td>
	</tr>

      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <?lsmb IF notes ?>
          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
    <?lsmb END ?>
  </tr>
</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (5, 'sales_quotation', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\setlength\LTleft{0pt}
\setlength\LTright{0pt}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

\newsavebox{\ftr}
\sbox{\ftr}{
  \parbox{\textwidth}{
  \tiny
  \rule[1.5em]{\textwidth}{0.5pt}
<?lsmb text(''Special order items are subject to a 10\% cancellation fee.'') ?>
  }
}

<?lsmb INCLUDE letterhead.tex ?>


\markboth{<?lsmb company ?>\hfill <?lsmb quonumber ?>}{<?lsmb company ?>\hfill <?lsmb quonumber ?>}

\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{

<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb contact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF customerphone ?>
<?lsmb text(''Tel: [_1]'', customerphone) ?> ?>
<?lsmb END ?>

<?lsmb IF customerfax ?>
<?lsmb text(''Fax: [_1]'', customerfax) ?>
<?lsmb END ?>

<?lsmb email ?>
}

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Quotation'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{6}{|X}|} \hline
  \textbf{<?lsmb text(''Quotation #'') ?>} & \textbf{<?lsmb text(''Date'') ?>} 
  & \textbf{<?lsmb text(''Valid until'') ?>} & \textbf{<?lsmb text(''Contact'') ?>} 
  & \textbf{<?lsmb text(''Shipping Point'') ?>} 
  & \textbf{<?lsmb text(''Ship via'') ?>} \\ [0.5ex]
  \hline
  <?lsmb quonumber ?> & <?lsmb quodate ?> & <?lsmb reqdate ?> & <?lsmb employee ?> & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}
  
\vspace{1cm}

\begin{longtable}{@{\extracolsep{\fill}}llrlrrr@{\extracolsep{0pt}}}
  \textbf{<?lsmb text(''Number'') ?>} & \textbf{<?lsmb text(''Description'') ?>} 
   & \textbf{<?lsmb text(''Qty'') ?>} & \textbf{<?lsmb text(''Unit'') ?>} 
   & \textbf{<?lsmb text(''Price'') ?>} & \textbf{<?lsmb text(''Disc %'') ?>} 
   & \textbf{<?lsmb text(''Amount'') ?>} 
\endhead
<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb qty.${lc} ?> &
  <?lsmb unit.${lc} ?> &
  <?lsmb sellprice.${lc} ?> &
  <?lsmb discountrate.${lc} ?> &
  <?lsmb linetotal.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\parbox{\textwidth}{
\rule{\textwidth}{2pt}

\vspace{0.2cm}

\hfill
\begin{tabularx}{7cm}{Xr@{\hspace{1cm}}r@{}}
  & Subtotal & <?lsmb subtotal ?> \\
<?lsmb FOREACH tax ?>
<?lsmb lc = loop.count - 1 ?>
  & <?lsmb taxdescription.${lc} ?> on <?lsmb taxbase.${lc} ?> & <?lsmb tax.${lc} ?>\\
<?lsmb END ?>
  \hline
  & Total & <?lsmb quototal ?>\\
\end{tabularx}

\vspace{0.3cm}

\hfill
<?lsmb text(''All prices in [_1].'', currency) ?>

<?lsmb IF terms ?>
<?lsmb text(''Terms: [_1] days'', terms) ?>
<?lsmb END ?>

\vspace{12pt}

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>

}

\vfill

\hfill \parbox{7cm}{X \rule{6.5cm}{0.5pt}}

\rule{\textwidth}{0.5pt}

\usebox{\ftr}

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (6, 'check', NULL, '<?lsmb FILTER latex ?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

<?lsmb REQUIRE check_base.tex ?>

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb PROCESS check_single ?>

\end{document}
<?lsmb END # FILTER latex ?>
', 'tex');
INSERT INTO template VALUES (9, 'work_order', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>


% Break old pagebreak directive
%<?xlsmb pagebreak 65 27 48 ?>
%\end{tabularx}
%
%\newpage
%
%\markboth{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}
%
%\begin{tabularx}{\textwidth}{@{}rlXrll@{}}
%  \textbf{Item} & \textbf{Number} & \textbf{Description} & \textbf{Qt''y} &
%  & \textbf{Serial Number} \\
%<?xlsmb end pagebreak ?>


\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
\textbf{To}
\vspace{0.3cm}
  
<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb contact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF customerphone ?>
<?lsmb text(''Tel: [_1]'', customerphone) ?>
<?lsmb END ?>

<?lsmb IF customerfax ?>
<?lsmb text(''Fax: [_1]'', customerfax) ?>
<?lsmb END ?>

<?lsmb email ?>
}
\parbox[t]{.5\textwidth}{
\textbf{Ship To}
\vspace{0.3cm}

<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate ?>
\hspace{-0.1cm}, <?lsmb shiptostate ?>
<?lsmb END ?>
<?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>

\vspace{0.3cm}

<?lsmb IF shiptocontact ?>
<?lsmb shiptocontact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF shiptophone ?>
<?lsmb text(''Tel: [_1]'', shiptophone) ?>
<?lsmb END ?>

<?lsmb IF shiptofax ?>
<?lsmb text(''Fax:[_1]'', shiptofax) ?>
<?lsmb END ?>

<?lsmb shiptoemail ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Work Order'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{6}{|X}|} \hline
  \textbf{Order \#} & \textbf{Order Date} & \textbf{Required by} & \textbf{Salesperson} & \textbf{Shipping Point} & \textbf{Ship Via} \\ [0.5em]
  \hline
  <?lsmb ordnumber ?> & <?lsmb orddate ?> & <?lsmb reqdate ?> & <?lsmb employee ?> & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}
  
\vspace{1cm}

\begin{longtable}{@{\extracolsep{\fill}}rllrll@{}}
  \textbf{<?lsmb text(''Item'') ?>} & \textbf{<?lsmb text(''Number'') ?>} 
  & \textbf{<?lsmb text(''Description'') ?>} & \textbf{<?lsmb text(''Qty'') ?>} &
  & \textbf{<?lsmb text(''Serial Number'') ?>} \\
<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb runningnumber.${lc} ?> &
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb qty.${lc} ?> &
  <?lsmb unit.${lc} ?> &
  <?lsmb serialnumber.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\parbox{\textwidth}{
\rule{\textwidth}{2pt}

\vspace{12pt}

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>
}

\vfill

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (11, 'ap_transaction', NULL, 'account,amount,description,project
<?lsmb FOREACH amount ?><?lsmb lc = loop.count - 1 ?><?lsmb accno.${lc} ?>,<?lsmb account.${lc} ?>,<?lsmb amount.${lc} ?>,<?lsmb description.${lc} ?>,<?lsmb projectnumber.${lc} ?>
<?lsmb END ?><?lsmb FOREACH t IN taxaccounts.split('' '') ?><?lsmb loop_count = loop.count - 1 -?>
<?lsmb t.remove(''"'') ?>,<?lsmb tax.${loop_count} ?>,<?lsmb taxdescription.${loop_count} ?>,
<?lsmb END ?>
', 'csv');
INSERT INTO template VALUES (12, 'invoice', NULL, '﻿<?lsmb INCLUDE ''ui-header.html'' ?>
<body>
<table width="100%">

  <?lsmb INCLUDE "letterhead.html" ?>
  
  <tr>
    <td width=10>&nbsp;</td>

    <th colspan=3>
      <h4 style="text-transform:uppercase">
          <?lsmb text(''Invoice'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
        <tr bgcolor=000000>
          <th align=left width="50%"><font color=ffffff><?lsmb text(''To'') ?></th>
          <th align=left width="50%"><font color=ffffff><?lsmb text(''Ship To'') ?>
          </th>
        </tr>

        <tr valign=top>
          <td><?lsmb name ?>
          <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
          <br><?lsmb address2 ?>
	  <?lsmb END ?>
          <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
          <br>

          <?lsmb IF contact ?>
          <br><?lsmb contact ?>
          <br>
          <?lsmb END ?>

          <?lsmb IF customerphone ?>
          <br><?lsmb text(''Tel: [_1]'', customerphone) ?>
          <?lsmb END ?>

          <?lsmb IF customerfax ?>
          <br><?lsmb text(''Fax: [_1]'', customerfax) ?>
          <?lsmb END ?>

          <?lsmb IF email ?>
          <br><?lsmb email ?>
          <?lsmb END ?>
          </td>

          <td><?lsmb shiptoname ?>
          <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
          <br><?lsmb shiptoaddress2 ?>
	  <?lsmb END ?>
          <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
	  <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
	  <br><?lsmb shiptocountry ?>
	  <?lsmb END ?>
          <br>

          <?lsmb IF shiptocontact ?>
          <br><?lsmb shiptocontact ?>
          <br>
          <?lsmb END ?>

          <?lsmb IF shiptophone ?>
          <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
          <?lsmb END ?>

          <?lsmb IF shiptofax ?>
          <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
          <?lsmb END ?>

          <?lsmb IF shiptoemail ?>
          <br><?lsmb shiptoemail ?>
          <?lsmb END ?>
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>
  
    <td>
      <table width=100% border=1>
        <tr>
	  <th width=14% align=left nowrap><?lsmb text(''Invoice #'') ?></th>
	  <th width=14% align=left nowrap><?lsmb text(''Date'') ?></th>
	  <th width=14% align=left nowrap><?lsmb text(''Due'') ?></th>
	  <th width=14% align=left><?lsmb text(''Order #'') ?></th>
	  <th width=14% align=left nowrap><?lsmb text(''Salesperson'') ?></th>
	  <th width=14% align=left nowrap><?lsmb text(''Shipping Point'') ?></th>
	  <th width=14% align=left nowrap><?lsmb text(''Ship via'') ?></th>
	</tr>

	<tr>
	  <td><?lsmb invnumber ?></td>
	  <td><?lsmb invdate ?></td>
	  <td><?lsmb duedate ?></td>
	  <td><?lsmb ordnumber ?>&nbsp;</td>
	  <td><?lsmb employee ?>&nbsp;</td>
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
  
    <td>
      <table width="100%">
        <tr bgcolor=000000>
          <th align=right><font color=ffffff><?lsmb text(''Item'') ?></th>
          <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
          <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
          <th>&nbsp;</th>
          <th align=right><font color=ffffff><?lsmb text(''Qty'') ?></th>
          <th>&nbsp;</th>
          <th align=right><font color=ffffff><?lsmb text(''Unit Price'') ?></th>
          <th align=right><font color=ffffff><?lsmb text(''Disc %'') ?></th>
          <th align=right><font color=ffffff><?lsmb text(''Extended'') ?></th>
        </tr>

        <?lsmb FOREACH number ?>
        <?lsmb loop_count = loop.count - 1 ?>
        <tr valign=top>
          <td align=right><?lsmb runningnumber.${loop_count} ?>.</td>
          <td><?lsmb number.${loop_count} ?></td>
          <td><?lsmb item_description.${loop_count} ?></td>
          <td><?lsmb deliverydate.${loop_count} ?></td>
          <td align=right><?lsmb qty.${loop_count} ?></td>
          <td><?lsmb unit.${loop_count} ?></td>
          <td align=right><?lsmb sellprice.${loop_count} ?></td>
          <td align=right><?lsmb discountrate.${loop_count} ?></td>
          <td align=right><?lsmb linetotal.${loop_count} ?></td>
        </tr>
        <?lsmb END ?>

        <tr>
          <td colspan=9><hr noshade></td>
        </tr>
    
        <tr>
          <?lsmb IF taxincluded ?>
          <th colspan=7 align=right><?lsmb text(''Total'') ?></th>
          <td colspan=2 align=right><?lsmb invtotal ?></td>
          <?lsmb ELSE ?>
          <th colspan=7 align=right><?lsmb text(''Subtotal'') ?></th>
          <td colspan=2 align=right><?lsmb subtotal ?></td>
          <?lsmb END ?>
        </tr>

        <?lsmb FOREACH tax ?>
	<?lsmb loop_count = loop.count - 1 ?>
        <tr>
          <th colspan=7 align=right><?lsmb taxdescription.${loop_count} ?> on <?lsmb taxbase.${loop_count} ?> @ <?lsmb taxrate.${loop_count} ?> %</th>
          <td colspan=2 align=right><?lsmb tax.${loop_count} ?></td>
        </tr>
        <?lsmb END ?>

        <?lsmb IF paid ?>
        <tr>
          <th colspan=7 align=right><?lsmb text(''Paid'') ?></th>
          <td colspan=2 align=right>- <?lsmb paid ?></td>
        </tr>
        <?lsmb END ?>

        <tr>
          <td colspan=5>&nbsp;</td>
          <td colspan=4><hr noshade></td>
        </tr>

        <?lsmb IF total ?>
        <tr>
          <td colspan=5>&nbsp;</td>
          <th colspan=2 align=right nowrap><?lsmb text(''Balance Due'') ?></th>
          <th colspan=2 align=right><?lsmb total ?></th>
        </tr>
        <?lsmb END ?>

        <tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width="100%">
        <tr valign=top>
          <?lsmb IF notes ?>
          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
          <?lsmb END ?>

	  <td><?lsmb text_amount ?> ***** <?lsmb decimal ?>/100</td>
	  
          <td align=right nowrap>
          <?lsmb text(''All prices in [_1]'', currency) ?>
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <?lsmb IF paid_1 ?>
  <tr>
    <td>&nbsp;</td>

    <td colspan=9>
      <table width="60%">

        <tr>
          <th align=left><?lsmb text(''Payments'') ?></th>
        </tr>

        <tr>
          <td colspan=4>
          <hr noshade>
          </td>
        </tr>

        <tr>
          <th align=left><?lsmb text(''Date'') ?></th>
          <th align=left><?lsmb text(''Account'') ?></th>
          <th align=left><?lsmb text(''Source'') ?></th>
          <th align=left><?lsmb text(''Amount'') ?></th>
        </tr>

        <?lsmb FOREACH payment ?>
	<?lsmb loop_count = loop.count - 1 ?>
        <tr>
          <td><?lsmb paymentdate.${loop_count} ?></td>
          <td><?lsmb paymentaccount.${loop_count} ?></td>
          <td><?lsmb paymentsource.${loop_count} ?></td>
          <td><?lsmb payment.${loop_count} ?></td>
        </tr>
        <?lsmb END ?>

      </table>
    </td>
  </tr>
  <?lsmb END ?>

  <tr height=10></tr>

  <tr>
    <td>&nbsp;</td>

    <th>
    <?lsmb text(''Thank you for your valued business!'') ?>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width="100%">
        <tr valign=top>
          <td width="60%"><font size=-3>
          <?lsmb text(''Payment due by [_1].'', duedate) ?>
          <?lsmb text(''Items returned are subject to a 10% restocking charge. A return authorization must be obtained from [_1] before goods are returned. Returns must be shipped prepaid and properly insured. [_1] will not be responsible for damages during transit.'', company) ?>
          </font>
          </td>

          <td width="40%">
          X <hr noshade>
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <?lsmb FOREACH tax ?>
  <?lsmb loop_count = loop.count - 1 ?>
  <tr>
    <td>&nbsp;</td>

    <th colspan=9 align=left><font size=-2><?lsmb taxdescription.${loop_count} ?> <?lsmb text(''Registration [_1]'', taxnumber.${loop_count}) ?></th>
  </tr>
  <?lsmb END ?>

  <?lsmb IF taxincluded ?>
  <tr>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <th colspan=8 align=left><font size=-2>
       <?lsmb text(''Taxes shown are included in price.'') ?></th>
  </tr>
  <?lsmb END ?>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (13, 'timecard', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Time Card'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>

    <th colspan=3>
      <h4 style="text-transform:uppercase">
        <?lsmb text(''Time Card'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
        <tr valign=top>
	  <td>
	    <table>
	      <tr>
		<th align=left><?lsmb text(''Employee'') ?></th>
		<td><?lsmb employee ?></td>
	      </tr>
	      <tr>
		<th align=left><?lsmb text(''ID'') ?></th>
		<td><?lsmb employee_id ?></td>
	      </tr>
	    </table>
	  </td>
   
	  <td align=right>
	    <table>
	      <tr>
		<th align=left nowrap><?lsmb text(''Card ID'') ?></th>
		<td><?lsmb id ?></td>
	      </tr>
	      <tr>
		<th align=left nowrap><?lsmb text(''Date'') ?></th>
		<td><?lsmb transdate ?></td>
	      </tr>
	      <tr>
		<th align=left nowrap><?lsmb text(''In'') ?></th>
		<td><?lsmb checkedin ?></td>
	      </tr>
              <tr>
                <th align=left><?lsmb text(''Out'') ?></th>
		<td><?lsmb checkedout ?></td>
	      </tr>
	      <tr>
		<th align=left nowrap><?lsmb text(''Hours'') ?></th>
		<td><?lsmb qty ?></td>
	      </tr>
	    </table>
	  </td>
        </tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>
  
    <td>
      <table width="100%">
        <tr valign=bottom>
	  <td>
	    <table>
	      <tr valign=top>
	        <th align=left><?lsmb text(''Job/Project #'') ?></th>
		<td><?lsmb projectnumber ?></td>
	      </tr>
	      <tr>
	        <th align=left><?lsmb text(''Description'') ?></th>
		<td><?lsmb projectdescription ?></td>
	      </tr>
	      <tr valign=top>
	        <th align=left><?lsmb text(''Labor/Service Code'') ?></th>
		<td><?lsmb partnumber ?></td>
	      </tr>
	      <tr>
	        <th align=left><?lsmb text(''Description'') ?></th>
		<td><?lsmb description ?></td>
	      </tr>
	    </table>
	  </td>
	  <td align=right>
	    <table>
	      <tr>
	        <th align=right><?lsmb text(''Rate'') ?></th>
		<td><?lsmb sellprice ?></td>
	      </tr>
	      <tr>
		<th align=right><?lsmb text(''Total'') ?></th>
		<td><?lsmb total ?></td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <?lsmb IF notes ?>
  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>

          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
  </tr>
  <?lsmb END ?>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (14, 'statement', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

<?lsmb FOREACH customer IN data ?>
<?lsmb import(customer) ?>
\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>

\parbox[t]{.5\textwidth}{
<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>
}
\parbox[t]{.5\textwidth}{
<?lsmb IF customerphone ?>
<?lsmb text(''Tel: [_1]'', customerphone) ?>
<?lsmb END ?>

<?lsmb IF customerfax ?>
<?lsmb text(''Fax: [_1]'', customerfax) ?>
<?lsmb END ?>

<?lsmb email ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Statement'') ?>}} \hfill 
\textbf{<?lsmb statementdate ?>}

\vspace{2cm}

\begin{tabular*}{\textwidth}{|ll@{\extracolsep\fill}ccrrrr|}
  \hline
  \textbf{<?lsmb text(''Invoice #'') ?>} & \textbf{<?lsmb text(''Order #'') ?>} 
  & \textbf{<?lsmb text(''Date'') ?>} & \textbf{<?lsmb text(''Due'') ?>} &
  \textbf{<?lsmb text(''Current'') ?>} & \textbf{30} & \textbf{60} & \textbf{90} \\
  \hline
<?lsmb FOREACH invnumber ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb invnumber.${lc} ?> &
  <?lsmb ordnumber.${lc} ?> &
  <?lsmb invdate.${lc} ?> &
  <?lsmb duedate.${lc} ?> &
  <?lsmb c0.${lc} ?> &
  <?lsmb c30.${lc} ?> &
  <?lsmb c60.${lc} ?> &
  <?lsmb c90.${lc} ?> \\
<?lsmb END ?>
  \multicolumn{8}{|l|}{\mbox{}} \\
  \hline
  \textbf{<?lsmb text(''Subtotal'') ?>} & & & & <?lsmb c0total ?> & <?lsmb c30total ?> & <?lsmb c60total ?> & <?lsmb c90total ?> \\
  \hline
\end{tabular*}

\vspace{0.5cm}

\hfill
\begin{tabularx}{\textwidth}{Xr@{\hspace{1cm}}r@{}}
  & \textbf{<?lsmb text(''Total outstanding'') ?>} & \textbf{<?lsmb total ?>}
\end{tabularx}

\vfill
<?lsmb text(''All amounts in [_1] funds.'', currency) ?>

<?lsmb text(''Please make check payable to [_1]'', company) ?>

<?lsmb IF NOT loop.last ?>
\pagebreak
<?lsmb END ?>
<?lsmb END ?>
\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (19, 'invoice', NULL, 'ISA*00*          *00*          *12*XXXXXXXXXX     *01*XXXXXXXXXX     *<?lsmb EDI_CURRENT_DATE ?>*<?lsmb EDI_CURRENT_TIME ?>*^*00501*<?lsmb FILTER format(''%09d''); id ; END ?>*0*P*>~
GS*DX*7196333434*031958655*<?lsmb EDI_CURRENT_DATE ?>*<?lsmb EDI_CURRENT_TIME ?>*0001*X*005010~
ST*894*<?lsmb id ?>~
G82*<?lsmb IF reverse; ''C''; ELSE; ''X''; END ?>*<?lsmb invnumber ?>*0001*0000*<?lsmb edidate(transdate) ?>~
<?lsmb t_qty = 0; FOREACH n IN number; lc = loop.count - 1; t_qty = t_qty + qty.${lc} -?>
LS*<?lsmb loop.count ?>~
G83*<?lsmb loop.count?>*<?lsmb qty.${lc} ?>*UC*<?lsmb number.${lc} ?>*<?lsmb FILTER format(''%.4f''); sellprice.${lc}; END ?>**~
LE*<?lsmb loop.count ?>~
<?lsmb END # FOREACH n in number -?>
G84*<?lsmb t_qty?>*<?lsmb invtotal ?>~
SE*<?lsmb (3 * lc) + 7 ?>*<?lsmb id ?>~
GE*1*0001~
IEA*1*<?lsmb FILTER format(''%09d''); id ; END ?>~
', '894');
INSERT INTO template VALUES (20, 'invoice', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
\usepackage{tabularx}
 \usepackage{fontspec}
\usepackage{longtable}
\setmainfont{LiberationSans-Regular.ttf}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}
\setlength\LTleft{0pt}
\setlength\LTright{0pt}
\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb BLOCK multiline -?>
\begin{minipage}{2in}
\medskip
\raggedright
<?lsmb string ?>
\end{minipage}
<?lsmb- END -?>

\newsavebox{\ftr}
\sbox{\ftr}{
  \parbox{\textwidth}{
  \tiny
  \rule[1.5em]{\textwidth}{0.5pt}
<?lsmb text(''Payment due NET [_1] Days from date of Invoice.'', terms) ?>
<?lsmb text(''Interest on overdue amounts will acrue at the rate of 12% per annum starting from [_1] until paid in full. Items returned are subject to a 10% restocking charge.'', duedate) ?>
<?lsmb text(''A return authorization must be obtained from [_1] before goods are returned. Returns must be shipped prepaid and properly insured. [_1] will not be responsible for damages during transit.'', company) ?>
  }
}

<?lsmb INCLUDE letterhead.tex ?>

\markboth{<?lsmb company ?>\hfill <?lsmb invnumber ?>}{<?lsmb company ?>\hfill <?lsmb invnumber ?>}

\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
\textbf{To}
\vspace{0.3cm}

<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state -?>
\hspace{-0.1cm}, <?lsmb state ?> <?lsmb END ?> <?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb contact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF customerphone ?>
Tel: <?lsmb customerphone ?>
<?lsmb END ?>

<?lsmb IF customerfax ?>
Fax: <?lsmb customerfax ?>
<?lsmb END ?>

<?lsmb email ?>
}
\parbox[t]{.5\textwidth}{
\textbf{<?lsmb text(''Ship To'') ?>}
\vspace{0.3cm}

<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate -?>
\hspace{-0.1cm}, <?lsmb shiptostate ?><?lsmb END ?> <?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>

\vspace{0.3cm}

<?lsmb IF shiptocontact ?>
<?lsmb shiptocontact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF shiptophone ?>
Tel: <?lsmb shiptophone ?>
<?lsmb END ?>

<?lsmb IF shiptofax ?>
Fax: <?lsmb shiptofax ?>
<?lsmb END ?>

<?lsmb shiptoemail ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Invoice'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{7}{|X}|} \hline
  \textbf{<?lsmb text(''Invoice #'') ?>} & \textbf{<?lsmb text(''Date'') ?>} 
      & \textbf{<?lsmb text(''Due'') ?>} & \textbf{<?lsmb text(''Order #'') ?>}
      & \textbf{<?lsmb text(''Salesperson'') ?>} 
      & \textbf{<?lsmb text(''Shipping Point'') ?>} 
      & \textbf{<?lsmb text(''Ship via'') ?>} \\ [0.5em]
  \hline
  <?lsmb invnumber ?> & <?lsmb invdate ?> & <?lsmb duedate ?> & <?lsmb ordnumber ?> & <?lsmb employee ?>
  & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}

\vspace{1cm}

\begin{longtable}{@{\extracolsep{\fill}}r|llcrlrr|r}

  \textbf{<?lsmb text(''Item'') ?>} 
  & \textbf{<?lsmb text(''Number'') ?>}
  & \textbf{<?lsmb text(''Description'') ?>} 
  & \textbf{<?lsmb text(''Delivery'') ?>} 
  & \textbf{<?lsmb text(''Qty'') ?>} 
  & \textbf{<?lsmb text(''Unit'') ?>} 
  & \textbf{<?lsmb text(''Price'') ?>} 
  &  \textbf{<?lsmb text(''Disc %'') ?>} 
  & \textbf{<?lsmb text(''Amount'') ?>} 
\endhead
<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb runningnumber.${lc} ?> & 
  <?lsmb number.${lc} ?> & 
  <?lsmb INCLUDE multiline string = item_description.${lc} ?> & 
  <?lsmb deliverydate.${lc} ?> &
  <?lsmb qty.${lc} ?> & 
  <?lsmb unit.${lc} ?> &
  <?lsmb sellprice.${lc} ?> &
  <?lsmb discountrate.${lc} ?> &
  <?lsmb linetotal.${lc} ?> \\
<?lsmb END ?>
\hline \hline
\multicolumn{8}{r|}{<?lsmb text(''Subtotal'') ?>} & <?lsmb subtotal ?> \\*
<?lsmb FOREACH tax ?>
<?lsmb lc = loop.count - 1 ?>
\multicolumn{8}{r|}{<?lsmb taxdescription.${lc} 
                    ?>  on <?lsmb taxbase.${lc} ?> }
 & <?lsmb tax.${lc} ?> \\*
<?lsmb END ?>
<?lsmb IF paid ?>
\multicolumn{8}{r|}{ <?lsmb text(''Paid'') ?> } & - <?lsmb paid ?> \\*
<?lsmb END ?>
<?lsmb IF total ?>
  \hline
  \hline
\multicolumn{8}{r|}{<?lsmb text(''Balance Due'') ?>} & <?lsmb total ?>\\
<?lsmb END ?>

\end{longtable}


\parbox{\textwidth}{

\vspace{0.2cm}

\hfill

\vspace{0.3cm}

<?lsmb text_amount ?> ***** <?lsmb decimal ?>/100
\hfill
<?lsmb text(''All prices in [_1].'', currency) ?>

\vspace{12pt}

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>
}

\vfill

<?lsmb IF paid_1 ?>
\begin{tabularx}{10cm}{@{}lXlr@{}}
  \textbf{<?lsmb text(''Payments'') ?>} & & & \\
  \hline
  \textbf{<?lsmb text(''Date'') ?>} & & \textbf{<?lsmb text(''Source'') ?>} 
  & \textbf{<?lsmb text(''Amount'') ?>} \\
<?lsmb END ?>
<?lsmb FOREACH payment ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb paymentdate.${lc} ?> & <?lsmb paymentaccount.${lc} ?> & <?lsmb paymentsource.${lc} ?> & <?lsmb payment.${lc} ?> \\
<?lsmb END ?>
<?lsmb IF paid_1 ?>
\end{tabularx}
<?lsmb END ?>

\vspace{1cm}

\centerline{\textbf{<?lsmb text(''Thank You for your valued business!'') ?>}}

\rule{\textwidth}{0.5pt}

\usebox{\ftr}

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (16, 'purchase_order', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Purchase Order'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>
  
    <th colspan=3>
      <h4 style="text-transform:uppercase">
             <?lsmb text(''Purchase Order'') ?>
      </h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width=100% cellspacing=0 cellpadding=0>
	<tr bgcolor=000000>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''To:'') ?></th>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''Ship To:'') ?></th>
	</tr>

	<tr valign=top>
	  <td><?lsmb name ?>
	  <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
	  <br><?lsmb address2 ?>
	  <?lsmb END ?>
	  <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
          <br>

	  <?lsmb IF contact ?>
	  <br><?lsmb text(''Attn: [_1]'', contact) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF vendorphone ?>
	  <br><?lsmb text(''Tel: [_1]'', vendorphone) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF vendorfax ?>
	  <br><?lsmb text(''Fax: [_1]'', vendorfax) ?>
	  <?lsmb END ?>
	  </td>

	  <td><?lsmb shiptoname ?>
	  <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
	  <br><?lsmb shiptoaddress2 ?>
	  <?lsmb END ?>
	  <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
	  <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
	  <br><?lsmb shiptocountry ?>
	  <?lsmb END ?>
          <br>

	  <?lsmb IF shiptocontact ?>
	  <br><?lsmb text(''Attn: [_1]'', shiptocontact) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF shiptophone ?>
	  <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF shiptofax ?>
	  <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
	  <?lsmb END ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% border=1>
	<tr>
	  <th width=17% align=left><?lsmb text(''Order #'') ?></th>
	  <th width=17% align=left><?lsmb text(''Order Date'') ?></th>
	  <th width=17% align=left><?lsmb text(''Required by'') ?></th>
	  <th width=17% align=left><?lsmb text(''Contact'') ?></th>
	  <th width=17% align=left><?lsmb text(''Shipping Point'') ?></th>
	  <th width=15% align=left><?lsmb text(''Ship Via'') ?></th>
	</tr>

	<tr>
	  <td><?lsmb ordnumber ?></td>
	  <td><?lsmb orddate ?></td>
	  <td><?lsmb reqdate ?></td>
	  <td><?lsmb employee ?></td>
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=right><font color=ffffff><?lsmb text(''Item'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Qty'') ?></th>
	  <th>&nbsp;</th>
	  <th><font color=ffffff><?lsmb text(''Price'') ?></th>
	  <th><font color=ffffff><?lsmb text(''%'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Amount'') ?></th>
	</tr>

        <?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
	  <td align=right><?lsmb runningnumber.${loop_count} ?>.</td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td><?lsmb unit.${loop_count} ?></td>
	  <td align=right><?lsmb sellprice.${loop_count} ?></td>
	  <td align=right><?lsmb discountrate.${loop_count} ?></th>
	  <td align=right><?lsmb linetotal.${loop_count} ?></td>
	</tr>
        <?lsmb END ?>

	<tr>
	  <td colspan=8><hr noshade></td>
	</tr>
	
	<tr>
          <?lsmb IF taxincluded ?>
	  <th colspan=7 align=right><?lsmb text(''Total'') ?></th>
	  <th colspan=1 align=right><?lsmb ordtotal ?></th>
          <?lsmb ELSE ?>
	  <th colspan=7 align=right><?lsmb text(''Subtotal'') ?></th>
	  <td colspan=1 align=right><?lsmb subtotal ?></td>
          <?lsmb END ?>
	</tr>

        <?lsmb FOREACH tax ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr>
	  <th colspan=7 align=right><?lsmb taxdescription.${loop_count} ?> on <?lsmb taxbase.${loop_count} ?> @ <?lsmb taxrate.${loop_count} ?> %</th>
	  <td colspan=1 align=right><?lsmb tax.${loop_count} ?></td>
	</tr>
        <?lsmb END ?>

	<tr>
	  <td colspan=4>&nbsp;</td>
	  <td colspan=4><hr noshade></td>
	</tr>
	
        <?lsmb IF NOT taxincluded ?>
	  <th colspan=7 align=right><?lsmb text(''Total'') ?></th>
	  <td colspan=1 align=right><?lsmb ordtotal ?></td>
        <?lsmb END ?>

        <?lsmb IF terms ?>
	<tr>
	  <td colspan=4><?lsmb text(''Terms Net [_1] days'', terms) ?></td>
	  <th colspan=3 align=right><?lsmb text(''Total'') ?></th>
	  <th colspan=1 align=right><?lsmb ordtotal ?></th>
	</tr>
        <?lsmb END ?>

        <?lsmb IF taxincluded ?>
	<tr>
	  <td colspan=2><?lsmb text(''Tax included'') ?></td>
	</tr>
        <?lsmb END ?>

	<tr>
	  <td>&nbsp;</td>
	</tr>
	
        <?lsmb IF ordtotal ?>
	<tr>
	  <td colspan=8 align=right>
	  <?lsmb text(''All prices in [_1] funds'', currency) ?>
	  </td>
	</tr>
        <?lsmb END ?>

      </table>
    </td>
  </tr>

  <?lsmb IF notes ?>
  <tr>
    <td>&nbsp;</td>
    
    <td>
    <table width="100%">
      <tr valign=top>
	<td><?lsmb text(''Notes'') ?></td>
          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
      </tr>

    </table>
    </td>
  </tr>
  <?lsmb END ?>

  <tr>
    <td>&nbsp;</td>
  
    <td>
      <table width="100%">
	<tr valign=top>
	  <td width="70%">&nbsp;</td>

	  <td width="30%">
	  X <hr noshade>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (24, 'envelope', NULL, '<?lsmb FILTER latex ?>
\documentclass{scrartcl}
\usepackage[latin1]{inputenc}
\usepackage{tabularx}
\usepackage[paperheight=11cm, paperwidth=23cm,top=3.5cm,bottom=3cm,left=12cm,right=1cm]{geometry}
\begin{document}
\thispagestyle{empty}
\noindent <?lsmb name ?>\\
<?lsmb address1 ?> \\
<?lsmb- IF address2 ?>
<?lsmb address2 ?> \\
<?lsmb- END ?>
<?lsmb city ?>
<?lsmb- IF state -?>, <?lsmb state ?> <?lsmb END ?> <?lsmb zipcode ?>\\
\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (22, 'bin_list', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>


% Breaking old pagebreak directives
%<?xlsmb pagebreak 65 27 37 ?>
%\end{tabularx}
%
%\newpage
%
%\markboth{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}
%
%\begin{tabularx}{\textwidth}{@{}rlXllrrll@{}}
%  \textbf{Item} & \textbf{Number} & \textbf{Description} & \textbf{Serial Number} & & \textbf{Qty} & \textbf{Recd} & & \textbf{Bin} \\
%<?xlsmb end pagebreak ?>


\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
\textbf{<?lsmb text(''From'') ?>}
\vspace{0.3cm}

<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>
}
\parbox[t]{.5\textwidth}{
\textbf{<?lsmb text(''Ship To'') ?>}
\vspace{0.3cm}

<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate ?>
\hspace{-0.1cm}, <?lsmb shiptostate ?>
<?lsmb END ?>
<?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Bin List'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{6}{|X}|} \hline
  \textbf{Order \#} & \textbf{Date} & \textbf{Contact}
  <?lsmb IF warehouse ?>
  & \textbf{<?lsmb text(''Warehouse'') ?>}
  <?lsmb END ?>
  & \textbf{<?lsmb text(''Shipping Point'') ?>} & \textbf{<?lsmb text(''Ship via'') ?>} \\ [0.5em]
  \hline
  
  <?lsmb ordnumber ?>
  <?lsmb IF shippingdate ?>
  & <?lsmb shippingdate ?>
  <?lsmb END ?>
  <?lsmb IF NOT shippingdate ?>
  & <?lsmb orddate ?>
  <?lsmb END ?>
  & <?lsmb employee ?>
  <?lsmb IF warehouse ?>
  & <?lsmb warehouse ?>
  <?lsmb END ?>
  & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}
  
\vspace{1cm}
  
\begin{longtable}{@{\extracolsep{\fill}}rllllrrll@{}}
  \textbf{<?lsmb text(''Item'') ?>} & \textbf{<?lsmb text(''Number'') ?>} 
     & \textbf{<?lsmb text(''Description'') ?>} & 
     \textbf{<?lsmb text(''Serial Number'') ?>} & 
    & \textbf{<?lsmb text(''Qty'') ?>} & \textbf{<?lsmb text(''Recd'') ?>} & 
    & \textbf{<?lsmb text(''Bin'') ?>} \\

<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb runningnumber.${lc} ?> &
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb serialnumber.${lc} ?> &
  <?lsmb deliverydate.${lc} ?> &
  <?lsmb qty.${lc} ?> &
  <?lsmb ship.${lc} ?> &
  <?lsmb unit.${lc} ?> &
  <?lsmb bin.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\rule{\textwidth}{2pt}

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (23, 'statement', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Statement'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<?lsmb FOREACH customer IN data ?>
<?lsmb import(customer) ?>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>
    
    <th colspan=3><h4 style="text-transform:uppercase">
         <?lsmb text(''Statement'') ?></h4></th>
    
  </tr>

  <tr>
    <td>&nbsp;</td>
    
    <td colspan=3 align=right><?lsmb statementdate ?></td>
  </tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr valign=top>
	  <td><?lsmb name ?>
	  <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
	  <br><?lsmb address2 ?>
	  <?lsmb END ?>
	  <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
	  <br>
          <?lsmb IF customerphone ?>
	  <br><?lsmb text(''Tel: [_1],'' customerphone) ?>
          <?lsmb END ?>
          <?lsmb IF customerfax ?>
	  <br><?lsmb text(''Fax: [_1]'', customerfax) ?>
          <?lsmb END ?>
          <?lsmb IF email ?>
	  <br><?lsmb email ?>
          <?lsmb END ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
  
  <tr height=10></tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
        <tr>
	  <th align=left><?lsmb text(''Invoice #'') ?></th>
          <th align=left><?lsmb text(''Order#'') ?></th>
	  <th width="10%"><?lsmb text(''Date'') ?></th>
	  <th width="10%"><?lsmb text(''Due'') ?></th>
	  <th width="10%"><?lsmb text(''Current'') ?></th>
	  <th width="10%"><?lsmb text(''30'') ?></th>
	  <th width="10%"><?lsmb text(''60'') ?></th>
	  <th width="10%"><?lsmb text(''90'') ?></th>
	</tr>
        
	<?lsmb FOREACH invnumber ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr>
	  <td><?lsmb invnumber.${loop_count} ?></td>
          <td><?lsmb ordnumber.${loop_count} ?></td>
	  <td><?lsmb invdate.${loop_count} ?></td>
	  <td><?lsmb duedate.${loop_count} ?></td>
	  <td align=right><?lsmb c0.${loop_count} ?></td>
	  <td align=right><?lsmb c30.${loop_count} ?></td>
	  <td align=right><?lsmb c60.${loop_count} ?></td>
	  <td align=right><?lsmb c90.${loop_count} ?></td>
	</tr>
        <?lsmb END ?>
	
        <tr>
	  <td colspan=8><hr size=1></td>
	</tr>
	
	<tr>
	  <td>&nbsp;</td>
	  <td>&nbsp;</td>
          <td>&nbsp;</td>
          <td>&nbsp;</td>
	  <th align=right><?lsmb c0total ?></td>
	  <th align=right><?lsmb c30total ?></td>
	  <th align=right><?lsmb c60total ?></td>
	  <th align=right><?lsmb c90total ?></td>
	</tr>
      </table>
    </td>
  </tr>
  
  <tr height=10></tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td align=right>
      <table width="50%">
        <tr>
	  <th><?lsmb text(''Total Outstanding'') ?></th>
          <th align=right><?lsmb total ?></th>
	</tr>
      </table>
    </td>
  </tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td><hr noshade></td>
  </tr>
  
  <tr>
    <td>&nbsp;</td>
    <td><?lsmb text(''All amounts in [_1] Funds'', currency) ?>
    <br><?lsmb text(''Please make check payable to [_1].'', company) ?>
    </td>
  </tr>

</table>

<?lsmb END ?>
</body>
</html>

', 'html');
INSERT INTO template VALUES (25, 'ar_transaction', NULL, 'account,description,amount,memo,project
<?lsmb FOREACH amount ?><?lsmb lc = loop.count - 1 ?><?lsmb accno.${lc} ?>,<?lsmb account.${lc} ?>,<?lsmb amount.${lc} ?>,<?lsmb description.${lc} ?>,<?lsmb projectnumber.${lc} ?>
<?lsmb END ?><?lsmb FOREACH t IN taxaccounts.split('' '') ?><?lsmb loop_count = loop.count - 1 -?>
<?lsmb t.remove(''"'') ?>,<?lsmb taxdescription.${loop_count} ?>,<?lsmb tax.${loop_count} ?>,,,
<?lsmb END ?>
', 'csv');
INSERT INTO template VALUES (28, 'sales_order', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\setlength\LTleft{0pt}
\setlength\LTright{0pt}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>


\markboth{<?lsmb company ?>\hfill <?lsmb ordnumber ?>}{<?lsmb company ?>\hfill <?lsmb ordnumber ?>}

\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
\textbf{To}
\vspace{0.3cm}
  
<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb contact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF customerphone ?>
<?lsmb text(''Tel: [_1]'', customerphone) ?>
<?lsmb END ?>

<?lsmb IF customerfax ?>
<?lsmb text(''Fax: [_1]'', customerfax) ?>
<?lsmb END ?>

<?lsmb email ?>
}
\parbox[t]{.5\textwidth}{
\textbf{Ship To}
\vspace{0.3cm}

<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate ?>
\hspace{-0.1cm}, <?lsmb shiptostate ?>
<?lsmb END ?>
<?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>

\vspace{0.3cm}

<?lsmb IF shiptocontact ?>
<?lsmb shiptocontact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF shiptophone ?>
<?lsmb text(''Tel: [_1]'', shiptophone) ?>
<?lsmb END ?>

<?lsmb IF shiptofax ?>
<?lsmb text(''Fax: [_1]'', shiptofax) ?>
<?lsmb END ?>

<?lsmb shiptoemail ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Sales Order'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{6}{|X}|} \hline
  \textbf{<?lsmb text(''Order #'') ?>} & \textbf{<?lsmb text(''Order Date'') ?>} 
  & \textbf{<?lsmb text(''Required by'') ?>} 
  & \textbf{<?lsmb text(''Salesperson'') ?>} 
  & \textbf{<?lsmb text(''Shipping Point'') ?>} 
  & \textbf{<?lsmb text(''Ship Via'') ?>} \\ [0.5em]
  \hline
  <?lsmb ordnumber ?> & <?lsmb orddate ?> & <?lsmb reqdate ?> & <?lsmb employee ?> & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}
  
\vspace{1cm}

\begin{longtable}{@{\extracolsep{\fill}}rlcrlrrr@{\extracolsep{0pt}}}
  \textbf{<?lsmb text(''Item'') ?>} & \textbf{<?lsmb text(''Number'') ?>} 
   & \textbf{<?lsmb text(''Description'') ?>} & \textbf{<?lsmb text(''Qty'') ?>} &
  \textbf{<?lsmb text(''Unit'') ?>} & \textbf{<?lsmb text(''Price'') ?>} 
  & \textbf{<?lsmb text(''Disc %'') ?>} 
  & \textbf{<?lsmb text(''Amount'') ?>} 
\endhead
<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb runningnumber.${lc} ?> &
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb qty.${lc} ?> &
  <?lsmb unit.${lc} ?> &
  <?lsmb sellprice.${lc} ?> &
  <?lsmb discountrate.${lc} ?> &
  <?lsmb linetotal.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\parbox{\textwidth}{
\rule{\textwidth}{2pt}

\vspace{0.2cm}

\hfill
\begin{tabularx}{7cm}{Xr@{\hspace{1cm}}r@{}}
  & Subtotal & <?lsmb subtotal ?> \\
<?lsmb FOREACH tax ?>
<?lsmb lc = loop.count - 1 ?>
  & <?lsmb taxdescription.${lc} ?> on <?lsmb taxbase.${lc} ?> & <?lsmb tax.${lc} ?>\\
<?lsmb END ?>
  \hline
  & Total & <?lsmb ordtotal ?>\\
\end{tabularx}

\vspace{0.3cm}

<?lsmb text_amount ?> ***** <?lsmb decimal ?>/100
\hfill
<?lsmb text(''All prices in [_1].'', currency) ?>

<?lsmb IF terms ?>
<?lsmb text(''Terms: Net [_1]  days'', terms) ?>
<?lsmb END ?>

\vspace{12pt}

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>

}

\vfill

\centerline{\textbf{<?lsmb text(''Thank You for your valued business!'') ?>}}

\rule{\textwidth}{0.5pt}

\end{document}
<?lsmb END -?>
', 'tex');
INSERT INTO template VALUES (30, 'letterhead', NULL, '  <tr>
    <td width=10>&nbsp;</td>

    <td>
      <table width="100%">
        <tr>
          <td>
            <h4>
            <?lsmb company ?><br>
            <?lsmb address ?>
            </h4>
          </td>
          <!-- Commenting out the image tag for now.  In general, folks can
               customize this to their servers, but if the server is behind a 
               firewall, then this won''t work.  Recommend that if people do this,
               they hardwire in a link to a publically accessible image. - CT -->
          <th><!-- <img src=<?lsmb images ?>/logo.png border=0 height=58> --></th>

          <td align=right>
            <h4>
            <?lsmb text(''Tel: [_1]'', tel) ?><br>
            <?lsmb text(''Fax: [_1]'', fax) ?>
            </h4>
          </td>
        </tr>

        <tr>
          <td colspan=3>
	    <hr noshade>
          </td>
        </tr>
      </table>
    </td>
  </tr>

', 'html');
INSERT INTO template VALUES (31, 'pick_list', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>


% Breaking old pagebreak directive
%<?xlsmb pagebreak 65 27 37 ?>
%\end{tabularx}
%
%\newpage
%
%\markboth{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}{<?xlsmb company ?>\hfill <?xlsmb ordnumber ?>}
%
%\begin{tabularx}{\textwidth}{@{}rlXrcll@{}}
%  \textbf{Item} & \textbf{Number} & \textbf{Description} &
%  \textbf{Qty} & \textbf{Ship} & & \textbf{Bin} \\
%
%<?xlsmb end pagebreak ?>

\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
  \textbf{Ship To}
} \hfill

\vspace{0.3cm}

\parbox[t]{.5\textwidth}{
  
<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate ?>
\hspace{-0.1cm}, <?lsmb shiptostate ?>
<?lsmb END ?>
<?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>
}
\parbox[t]{.5\textwidth}{
  <?lsmb shiptocontact ?>

  <?lsmb IF shiptophone ?>
  Tel: <?lsmb shiptophone ?>
  <?lsmb END ?>

  <?lsmb IF shiptofax ?>
  Fax: <?lsmb shiptofax ?>
  <?lsmb END ?>

  <?lsmb shiptoemail ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Pick List'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{7}{|X}|} \hline
  \textbf{<?lsmb text(''Invoice #'') ?>} & \textbf{<?lsmb text(''Order #'') ?>} 
   & \textbf{<?lsmb text(''Date'') ?>} & \textbf{<?lsmb text(''Contact'') ?>}
  & \textbf{<?lsmb text(''Warehouse'') ?>} 
  & \textbf{<?lsmb text(''Shipping Point'') ?>} 
  & \textbf{<?lsmb text(''Ship via'') ?>} \\ [0.5em]
  \hline
  <?lsmb invnumber ?> & <?lsmb ordnumber ?>
  <?lsmb IF shippingdate ?>
  & <?lsmb shippingdate ?>
  <?lsmb ELSE ?>
  & <?lsmb transdate ?>
  <?lsmb END ?>
  & <?lsmb employee ?> & <?lsmb warehouse ?> & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}
  
\vspace{1cm}

\begin{longtable}{@{\extracolsep{\fill}}rllrcll@{}}
  \textbf{<?lsmb text(''Item'') ?>} & \textbf{<?lsmb text(''Number'') ?>} 
   & \textbf{<?lsmb text(''Description'') ?>} &
  \textbf{<?lsmb text(''Qty'') ?>} & \textbf{<?lsmb text(''Ship'') ?>} & 
  & \textbf{<?lsmb text(''Bin'') ?>} \\
<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb runningnumber.${lc} ?> &
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb qty.${lc} ?> & [\hspace{1cm}] &
  <?lsmb unit.${lc} ?> & <?lsmb bin.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\parbox{\textwidth}{
\rule{\textwidth}{2pt}
}

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (36, 'letterhead', NULL, '\parbox{\textwidth}{%
  \parbox[b]{.42\textwidth}{%
    <?lsmb company ?>
   
    <?lsmb address ?>
  }
  \parbox[b]{.2\textwidth}{
    % If you want to use a logo uncomment this and set images to
    % an absolute path to the images, or set the path appropriately here.
    %\includegraphics[scale=0.3]{<?lsmb images ?>/logo}
  }\hfill
  \begin{tabular}[b]{rr@{}}
  <?lsmb text(''Tel:'') ?> & <?lsmb tel ?>\\
  <?lsmb text(''Fax:'') ?> & <?lsmb fax ?>
  \end{tabular}

  \rule[1.5em]{\textwidth}{0.5pt}
}

', 'tex');
INSERT INTO template VALUES (37, 'ar_transaction', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage[top=2cm,bottom=1.5cm,left=2cm,right=1cm]{geometry}
\usepackage{graphicx}
\setlength{\parindent}{0pt}

\begin{document}

\pagestyle{empty}

\parbox{\textwidth}{%
  \parbox[b]{.42\textwidth}{%
    <?lsmb company ?>
   
    <?lsmb address ?>
  }
  %\parbox[b]{.2\textwidth}{
    %\includegraphics[scale=0.3]{ledger-smb}
  %}
  \hfill
  \begin{tabular}[b]{rr@{}}
  <?lsmb text(''Tel:'') ?> & <?lsmb tel ?>\\
  <?lsmb text(''Fax:'') ?> & <?lsmb fax ?>
  \end{tabular}

  \rule[1.5em]{\textwidth}{0.5pt}
}

\centerline{\MakeUppercase{<?lsmb text(''AR Transaction'') ?>}}

\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb contact ?>
<?lsmb END ?>

\vspace{0.2cm}

<?lsmb IF customerphone ?>
<?lsmb text(''Tel: [_1]'', customerphone) ?>
<?lsmb END ?>

<?lsmb IF customerfax ?>
<?lsmb text(''Fax: [_1]'', customerfax) ?>
<?lsmb END ?>

<?lsmb email ?>

<?lsmb IF customertaxnumber ?>
<?lsmb text(''Tax Number: [_1]'', customertaxnumber) ?>
<?lsmb END ?>
}
\hfill
\begin{tabular}[t]{ll}
  \textbf{<?lsmb text(''Invoice #'') ?>} & <?lsmb invnumber ?> \\
  \textbf{<?lsmb text(''Date'') ?>} & <?lsmb invdate ?> \\
  \textbf{<?lsmb text(''Due'') ?>} & <?lsmb duedate ?> \\
  <?lsmb IF ponumber ?>
    \textbf{PO \#} & <?lsmb ponumber ?> \\
  <?lsmb END ?>
  <?lsmb IF ordnumber ?>
    \textbf{<?lsmb text(''Order #'') ?>} & <?lsmb ordnumber ?> \\
  <?lsmb END ?>
  \textbf{<?lsmb text(''Employee'') ?>} & <?lsmb employee ?> \\
\end{tabular}

\vspace{1cm}

\begin{tabularx}{\textwidth}[t]{@{}llrX@{\hspace{1cm}}l@{}}
<?lsmb FOREACH amount ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb accno.${lc} ?> &
  <?lsmb account.${lc} ?> &
  <?lsmb amount.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb projectnumber.${lc} ?> \\
<?lsmb END ?>

  \multicolumn{2}{r}{\textbf{Subtotal}} & <?lsmb subtotal ?> & \\
<?lsmb FOREACH tax ?>
<?lsmb lc = loop.count - 1 ?>
  \multicolumn{2}{r}{\textbf{<?lsmb taxdescription.${lc} ?> @ <?lsmb taxrate.${lc} ?> \%}} & <?lsmb tax.${lc} ?> & \\
<?lsmb END ?>

  \multicolumn{2}{r}{\textbf{Total}} & <?lsmb invtotal ?> & \\
  
\end{tabularx}

\vspace{0.3cm}

<?lsmb text_amount ?> ***** <?lsmb decimal ?>/100 <?lsmb currency ?>

<?lsmb IF notes ?>
\vspace{0.3cm}
<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>
<?lsmb END ?>

\vspace{0.3cm}

<?lsmb IF paid_1 ?>
\begin{tabular}{@{}lllr@{}}
  \multicolumn{5}{c}{\textbf{<?lsmb text(''Payments'') ?>}} \\
  \hline
  \textbf{<?lsmb text(''Date'') ?>} & & \textbf{<?lsmb text(''Source'') ?>} & 
        \textbf{<?lsmb text(''Amount'') ?>} \\
<?lsmb END ?>
<?lsmb FOREACH payment ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb paymentdate.${lc} ?> & <?lsmb paymentaccount.${lc} ?> & <?lsmb paymentsource.${lc} ?> & <?lsmb payment.${lc} ?> \\
<?lsmb END ?>
<?lsmb IF paid_1 ?>
\end{tabular}
<?lsmb END ?>

\vspace{0.5cm}

<?lsmb FOREACH tax ?>
<?lsmb lc = loop.count - 1 ?>
\textbf{\scriptsize <?lsmb taxdescription.${lc} _ '' '' _ text(''Registration'') _ '' '' _  taxnumber.${lc} ?>} \\
<?lsmb END ?>
  
\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (33, 'check_multiple', NULL, '<?lsmb FILTER latex ?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{graphicx}
\usepackage{textpos}

<?lsmb PROCESS check_base.tex ?>

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb FOR check = checks ?>
<?lsmb INCLUDE check_single 
	source = check.source
	control_code = check.control_code
	text_amount = check.text_amount
	decimal = check.decimal
	amount = check.amount
	legal_name = check.legal_name
	street1 = check.street1 
	street2 = check.street2 
	city = check.city
	state = check.state
	mail_code = check.mail_code
	country = check.country
	memo = check.memo
	invoices = check.invoices
?>
\clearpage
<?lsmb END # FOR check ?>
\end{document}
<?lsmb END # FILTER latex ?>
', 'tex');
INSERT INTO template VALUES (7, 'ar_transaction', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''AR Transaction'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>

  <tr>
    <td width=10>&nbsp;</td>

    <th colspan=3>
      <h4 style="text-transform:uppercase">
          <?lsmb text(''AR Transaction'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
        <tr valign=top>
          <td><?lsmb name ?>
          <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
          <br><?lsmb address2 ?>
	  <?lsmb END ?>
          <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
          <br>

          <?lsmb IF contact ?>
          <br><?lsmb contact ?>
          <br>
          <?lsmb END ?>

          <?lsmb IF customerphone ?>
          <br><?lsmb text(''Tel:'') _ '' '' _ customerphone ?>
          <?lsmb END ?>

          <?lsmb IF customerfax ?>
          <br><?lsmb text(''Fax:'') _ '' '' _ customerfax ?>
          <?lsmb END ?>

          <?lsmb IF email ?>
          <br><?lsmb email ?>
          <?lsmb END ?>

          <?lsmb IF customertaxnumber ?>
          <br><?lsmb text(''Taxnumber:'') _ '' '' _ customertaxnumber ?>
          <?lsmb END ?>
          </td>
   
	  <td align=right>
	    <table>
	      <tr>
		<th align=left nowrap><?lsmb text(''Invoice #'') ?></th>
		<td><?lsmb invnumber ?></td>
	      </tr>
	      <tr>
		<th align=left nowrap><?lsmb text(''Date'') ?></th>
		<td><?lsmb invdate ?></td>
	      </tr>
	      <tr>
		<th align=left nowrap><?lsmb text(''Due'') ?></th>
		<td><?lsmb duedate ?></td>
	      </tr>
	      <?lsmb IF ponumber ?>
              <tr>
                <th align=left><?lsmb text(''PO #'') ?></th>
		<td><?lsmb ponumber ?>&nbsp;</td>
	      </tr>
	      <?lsmb END ?>
	      <?lsmb IF ordnumber ?>
	      <tr>
		<th align=left><?lsmb text(''Order #'') ?></th>
		<td><?lsmb ordnumber ?>&nbsp;</td>
	      </tr>
	      <?lsmb END ?>
	      <tr>
		<th align=left nowrap><?lsmb text(''Salesperson'') ?></th>
		<td><?lsmb employee ?>&nbsp;</td>
	      </tr>
	    </table>
	  </td>
        </tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>
  
    <td>
      <table>
	<?lsmb FOREACH account ?>
        <?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
	  <td><?lsmb accno.${loop_count} ?></td>
	  <td><?lsmb account.${loop_count} ?></td>
	  <td width=10>&nbsp;</td>
	  <td align=right><?lsmb amount.${loop_count} ?></td>
	  <td width=10>&nbsp;</td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td width=10>&nbsp;</td>
	  <td><?lsmb projectnumber.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

	<tr>
	  <?lsmb IF taxincluded ?>
	  <th colspan=2 align=right><?lsmb text(''Total'') ?></th>
	  <td width=10>&nbsp;</td>
	  <td align=right><?lsmb invtotal ?></td>
	  <?lsmb ELSE ?>
	  <th colspan=2 align=right><?lsmb text(''Subtotal'') ?></th>
	  <td width=10>&nbsp;</td>
	  <td align=right><?lsmb subtotal ?></td>
	  <?lsmb END ?>
	</tr>

	<?lsmb FOREACH tax ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr>
	  <th colspan=2 align=right><?lsmb taxdescription.${loop_count} ?> @ <?lsmb taxrate.${loop_count} ?> %</th>
	  <td width=10>&nbsp;</td>
	  <td align=right><?lsmb tax.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>
	
	<?lsmb IF NOT taxincluded ?>
	<tr>
	  <th colspan=2 align=right><?lsmb text(''Total'') ?></th>
	  <td width=10>&nbsp;</td>
	  <td align=right><?lsmb invtotal ?></td>
	</tr>
	<?lsmb END ?>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <?lsmb text_amount ?> ***** <?lsmb decimal ?>/100 <?lsmb currency ?>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
  </tr>

  <?lsmb IF paid_1 ?>
  <tr>
    <td>&nbsp;</td>

    <td>
      <table>
        <tr>
          <th><?lsmb text(''Payments'') ?></th>
        </tr>

        <tr>
          <td>
          <hr noshade>
          </td>
        </tr>

	<tr>
	  <td>
	    <table>
	      <tr>
		<th><?lsmb text(''Date'') ?></th>
		<th>&nbsp;</th>
		<th><?lsmb text(''Source'') ?></th>
		<th><?lsmb text(''Amount'') ?></th>
	      </tr>
  <?lsmb END ?>

        <?lsmb FOREACH payment ?>
	<?lsmb loop_count = loop.count - 1 ?>
	      <tr>
		<td><?lsmb paymentdate.${loop_count} ?></td>
		<td><?lsmb paymentaccount.${loop_count} ?></td>
		<td><?lsmb paymentsource.${loop_count} ?></td>
		<td align=right><?lsmb payment.${loop_count} ?></td>
	      </tr>
        <?lsmb END ?>

  <?lsmb IF paid_1 ?>
	    </table>
	  </td>
        </tr>
      </table>
    </td>
  </tr>
  <?lsmb END ?>

  <tr height=10></tr>

  <?lsmb FOREACH tax ?>
  <?lsmb loop_count = loop.count - 1 ?>
  <tr>
    <td>&nbsp;</td>

    <th colspan=9 align=left><font size=-2><?lsmb taxdescription.${loop_count} ?> <?lsmb text(''Registration'') _ '' '' _  taxnumber.${loop_count} ?></th>
  </tr>
  <?lsmb END ?>

  <?lsmb IF taxincluded ?>
  <tr>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <th colspan=3 align=left><font size=-2>
         <?lsmb text(''Taxes shown are included in price.'') ?></th>
  </tr>
  <?lsmb END ?>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (8, 'ap_transaction', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}
\setlength{\parindent}{0pt}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>

\centerline{\MakeUppercase{\textbf{<?lsmb text(''AP Transaction'') ?>}}}

\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?> <?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb contact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF vendorphone ?>
Tel: <?lsmb vendorphone ?>
<?lsmb END ?>

<?lsmb IF vendorfax ?>
Fax: <?lsmb vendorfax ?>
<?lsmb END ?>

<?lsmb email ?>

<?lsmb IF vendortaxnumber ?>
Tax Number: <?lsmb vendortaxnumber ?>
<?lsmb END ?>
}
\hfill
\begin{tabular}[t]{ll}
  \textbf{<?lsmb text(''Invoice #'') ?>} & <?lsmb invnumber ?> \\
  \textbf{<?lsmb text(''Date'') ?>} & <?lsmb invdate ?> \\
  \textbf{<?lsmb text(''Due'') ?>} & <?lsmb duedate ?> \\
  <?lsmb IF ponumber ?>
    \textbf{<?lsmb text(''PO #'') ?>} & <?lsmb ponumber ?> \\
  <?lsmb END ?>
  <?lsmb IF ordnumber ?>
    \textbf{<?lsmb text(''Order #'') ?>} & <?lsmb ordnumber ?> \\
  <?lsmb END ?>
  \textbf{<?lsmb text(''Employee'') ?>} & <?lsmb employee ?> \\
\end{tabular}

\vspace{1cm}

\begin{tabularx}{\textwidth}[t]{@{}llrX@{\hspace{1cm}}l@{}}
<?lsmb FOREACH amount ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb accno.${lc} ?> &
  <?lsmb account.${lc} ?> &
  <?lsmb amount.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb projectnumber.${lc} ?> \\
<?lsmb END ?>

  \multicolumn{2}{r}{\textbf{Subtotal}} & <?lsmb subtotal ?> & \\
<?lsmb FOREACH tax ?>
<?lsmb lc = loop.count - 1 ?>
  \multicolumn{2}{r}{\textbf{<?lsmb taxdescription.${lc} ?> @ <?lsmb taxrate.${lc} ?> \%}} & <?lsmb tax.${lc} ?> & \\
<?lsmb END ?>

  \multicolumn{2}{r}{\textbf{Total}} & <?lsmb invtotal ?> & \\
  
\end{tabularx}

\vspace{0.3cm}

<?lsmb text_amount ?> ***** <?lsmb decimal ?>/100 <?lsmb currency ?>

<?lsmb IF notes ?>
\vspace{0.3cm}
<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>
<?lsmb END ?>

\vspace{0.3cm}

<?lsmb IF paid_1 ?>
\begin{tabular}{@{}llllr@{}}
  \multicolumn{5}{c}{\textbf{<?lsmb text(''Payments'') ?>}} \\
  \hline
  \textbf{<?lsmb text(''Date'') ?>} & & \textbf{<?lsmb text(''Source'') ?>} & \textbf{<?lsmb text(''Memo'') ?>} & \textbf{<?lsmb text(''Amount'') ?>} \\
<?lsmb END ?>
<?lsmb FOREACH payment ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb paymentdate.${lc} ?> & <?lsmb paymentaccount.${lc} ?> & <?lsmb paymentsource.${lc} ?> & <?lsmb paymentmemo.${lc} ?> & <?lsmb payment.${lc} ?> \\
<?lsmb END ?>
<?lsmb IF paid_1 ?>
\end{tabular}
<?lsmb END ?>

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (10, 'receipt', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

\parbox[t]{12cm}{
  <?lsmb company ?>

  <?lsmb address ?>}
\hfill
\parbox[t]{6cm}{\hfill <?lsmb source ?>}

\vspace*{0.6cm}

<?lsmb text_amount ?> \dotfill <?lsmb decimal ?>/100 \makebox[0.5cm]{\hfill}

\vspace{0.5cm}

\hfill <?lsmb datepaid ?> \makebox[2cm]{\hfill} <?lsmb amount ?>

% different date format for datepaid
% <?lsmb DD ?><?lsmb MM ?><?lsmb YYYY ?>

\vspace{0.5cm}

<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>

\vspace{1.8cm}

<?lsmb memo ?>

\vspace{0.8cm}

<?lsmb company ?>

\vspace{0.5cm}

<?lsmb name ?> \hfill <?lsmb datepaid ?> \hfill <?lsmb source ?>

\vspace{0.5cm}
\begin{tabularx}{\textwidth}{lXrr@{}}
\textbf{<?lsmb text(''Invoice No.'') ?>} & \textbf{<?lsmb text(''Invoice Date'') ?>}
  & \textbf{<?lsmb text(''Due'') ?>} & \textbf{<?lsmb text(''Applied'') ?>} \\
<?lsmb FOREACH invnumber ?>
<?lsmb lc = loop.count - 1 ?>
<?lsmb invnumber.${lc} ?> & <?lsmb invdate.${lc} ?> \dotfill
  & <?lsmb due.${lc} ?> & <?lsmb paid.${lc} ?> \\
<?lsmb END ?>
\end{tabularx}

\vspace{1cm}

<?lsmb memo ?>

\vfill

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (15, 'sales_quotation', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Quotation'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>
  
    <th colspan=3 style="text-transform:uppercase">
      <h4><?lsmb text(''Quotation'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">

	<tr valign=top>
	  <td><?lsmb name ?>
	  <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
	  <br><?lsmb address2 ?>
	  <?lsmb END ?>
	  <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>

	  <br>
	  <?lsmb IF contact ?>
	  <br><?lsmb text(''Attn: [_1]'', contact) ?>
	  <?lsmb END ?>

	  <?lsmb IF customerphone ?>
	  <br><?lsmb text(''Tel: [_1]'', customerphone) ?>
	  <?lsmb END ?>

	  <?lsmb IF customerfax ?>
	  <br><?lsmb text(''Fax: [_1]'', customerfax) ?>
	  <?lsmb END ?>

	  <?lsmb IF email ?>
	  <br><?lsmb email ?>
	  <?lsmb END ?>
	  </td>

	</tr>
      </table>
    </td>
  </tr>
    
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width=100% border=1>
	<tr>
	  <th width=17% align=left nowrap><?lsmb text(''Number'') ?></th>
	  <th width=17% align=left><?lsmb text(''Date'') ?></th>
	  <th width=17% align=left><?lsmb text(''Valid until'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Contact'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Shipping Point'') ?></th>
	  <th width=15% align=left nowrap><?lsmb text(''Ship via'') ?></th>
	</tr>

	<tr>
	  <td><?lsmb quonumber ?></td>
	  <td><?lsmb quodate ?></td>
	  <td><?lsmb reqdate ?></td>
	  <td><?lsmb employee ?></td>
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
  
    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=right><font color=ffffff><?lsmb text(''Item'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Qty'') ?></th>
	  <th>&nbsp;</th>
	  <th><font color=ffffff><?lsmb text(''Price'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Disc %'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Amount'') ?></th>
	</tr>

        <?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
	  <td align=right><?lsmb runningnumber.${loop_count} ?></td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td><?lsmb unit.${loop_count} ?></td>
	  <td align=right><?lsmb sellprice.${loop_count} ?></td>
	  <td align=right><?lsmb discountrate.${loop_count} ?></td>
	  <td align=right><?lsmb linetotal.${loop_count} ?></td>
	</tr>
        <?lsmb END ?>

	<tr>
	  <td colspan=8><hr noshade></td>
	</tr>
	
	<tr>
	  <?lsmb IF taxincluded ?>
	  <th colspan=6 align=right><?lsmb text(''Total'') ?></th>
	  <td colspan=2 align=right><?lsmb invtotal ?></td>
	  <?lsmb ELSE ?>
	  <th colspan=6 align=right><?lsmb text(''Subtotal'') ?></th>
	  <td colspan=2 align=right><?lsmb subtotal ?></td>
	  <?lsmb END ?>
	</tr>

	<?lsmb FOREACH tax ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr>
	  <th colspan=6 align=right><?lsmb taxdescription.${loop_count} ?> on <?lsmb taxbase.${loop_count} ?> @ <?lsmb taxrate.${loop_count} ?> %</th>
	  <td colspan=2 align=right><?lsmb tax.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

	<tr>
	  <td colspan=4>&nbsp;</td>
	  <td colspan=4><hr noshade></td>
	</tr>

	<tr>
	  <td colspan=4>&nbsp;
	  <?lsmb IF terms ?>
	  <?lsmb text(''Terms Net [_1] days'', terms) ?>
	  <?lsmb END ?>
	  </td>
	  <th colspan=2 align=right><?lsmb text(''Total'') ?></th>
	  <th colspan=2 align=right><?lsmb quototal ?></th>
	</tr>
	
	<tr>
	  <td>&nbsp;</td>
	</tr>

      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr valign=top>
          <?lsmb IF notes ?>
	  <td><?lsmb text(''Notes'') ?></td>
          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
          <?lsmb END ?>
	  <td align=right>
	  <?lsmb text(''All prices in [_1] Funds'', currency) ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width="100%">
	<tr valign=top>
	  <td width="60%"><font size=-3>
	  <?lsmb 
             text(''Special order items are subject to a 10% cancellation fee.'')
           ?>
	  </font>
	  </td>
	  <td width="40%">
	  X <hr noshade>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (21, 'packing_list', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Packing List'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td> 
    
    <th colspan=3>
      <h4 style="text-transform:uppercase">
           <?lsmb text(''Packing List'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
	<tr bgcolor=000000>
	  <th width=50% align=left><font color=ffffff>
               <?lsmb text(''Ship To:'') ?>
          </th>
	  <th width="50%">&nbsp;</th>
	</tr>

	<tr valign=top>
	  <td><?lsmb shiptoname ?>
	  <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
	  <br><?lsmb shiptoaddress2 ?>
	  <?lsmb END ?>
	  <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
	  <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
	  <br><?lsmb shiptocountry ?>
	  <?lsmb END ?>
	  </td>
	
	  <td>
	  <?lsmb IF shiptocontact ?>
	  <br><?lsmb text(''Attn: [_1]'', shiptocontact) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF shiptophone ?>
	  <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF shiptofax ?>
	  <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
	  <?lsmb END ?>

	  <?lsmb shiptoemail ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% border=1>
	<tr>
	  <th width=17% align=left><?lsmb text(''Invoice #'') ?></th>
	  <th width=17% align=left><?lsmb text(''Order #'') ?></th>
	  <th width=17% align=left><?lsmb text(''Date'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Contact'') ?></th>
	  <?lsmb IF warehouse ?>
	  <th width=17% align=left><?lsmb text(''Warehouse'') ?></th>
	  <?lsmb END ?>
	  <th width=17% align=left><?lsmb text(''Shipping Point'') ?></th>
	  <th width=15% align=left><?lsmb text(''Ship via'') ?></th>
	</tr>

        <tr>
	  <td><?lsmb invnumber ?>&nbsp;</td>
	  <td><?lsmb ordnumber ?>&nbsp;</td>
	  
	  <?lsmb IF shippingdate ?>
	  <td><?lsmb shippingdate ?></td>
	  <?lsmb ELSE ?>
	  <td><?lsmb transdate ?></td>
	  <?lsmb END ?>
  
          <td><?lsmb employee ?>&nbsp;</td>
	  
	  <?lsmb IF warehouse ?>
	  <td><?lsmb warehouse ?>&nbsp;</td>
	  <?lsmb END ?>

	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=left><font color=ffffff><?lsmb text(''Item'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Serial #'') ?></th>
	  <th>&nbsp;</th>
	  <th><font color=ffffff><?lsmb text(''Qty'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Ship'') ?></th>
	  <th>&nbsp;</th>
	</tr>

	<?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
	  <td><?lsmb runningnumber.${loop_count} ?></td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td><?lsmb serialnumber.${loop_count} ?></td>
	  <td><?lsmb deliverydate.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td align=right><?lsmb ship.${loop_count} ?></td>
	  <td><?lsmb unit.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td><hr noshade></td>
  </tr>

  <?lsmb IF notes ?>
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr valign=top>
	  <td>Notes</td>
          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
	</tr>
      </table>
    </td>
  </tr>
  <?lsmb END ?>

  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr valign=top>
	  <td width="70%"><font size=-3>
	  <?lsmb text(''Items returned are subject to a 10% restocking charge. A return authorization must be obtained from [_1] before goods are returned. Returns must be shipped prepaid and properly insured. [_1] will not be responsible for damages during transit.'', company) ?>
	  </font>
	  </td>
	  <td width="30%">
	  X <hr noshade>
	  </td>
	</tr>
      </table>
    </td>
  </tr>
</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (27, 'purchase_order', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\setlength\LTleft{0pt}
\setlength\LTright{0pt}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}


\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>


\markboth{<?lsmb company ?>\hfill <?lsmb ordnumber ?>}{<?lsmb company ?>\hfill <?lsmb ordnumber ?>}

\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
\textbf{To}
\vspace{0.3cm}
  
<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb text(''Attn: [_1]'', contact) ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF vendorphone ?>
<?lsmb text(''Tel: [_1]'', vendorphone) ?>
<?lsmb END ?>

<?lsmb IF vendorfax ?>
<?lsmb text(''Fax: [_1]'', vendorfax) ?>
<?lsmb END ?>

<?lsmb email ?>
}
\parbox[t]{.5\textwidth}{
\textbf{Ship To}
\vspace{0.3cm}

<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate ?>
\hspace{-0.1cm}, <?lsmb shiptostate ?>
<?lsmb END ?>
<?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>

\vspace{0.3cm}

<?lsmb IF shiptocontact ?>
<?lsmb text(''Attn: [_1]'', shiptocontact) ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF shiptophone ?>
<?lsmb text(''Tel: [_1]'', shiptophone) ?>
<?lsmb END ?>/

<?lsmb IF shiptofax ?>
<?lsmb text(''Fax: [_1]'', shiptofax) ?>
<?lsmb END ?>

<?lsmb shiptoemail ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Purchase Order'') ?>}}
\hfill

\vspace{1cm}
\begin{tabularx}{\textwidth}{*{6}{|X}|} \hline
  \textbf{<?lsmb text(''Order #'') ?>} & \textbf{<?lsmb text(''Date'') ?>} 
   & \textbf{<?lsmb text(''Required by'') ?>} & \textbf{<?lsmb text(''Contact'') ?>} 
   & \textbf{<?lsmb text(''Shipping Point'') ?>} 
   & \textbf{<?lsmb text(''Ship via'') ?>} \\ [0.5ex]
  \hline
  <?lsmb ordnumber ?> & <?lsmb orddate ?> & <?lsmb reqdate ?> & <?lsmb employee ?> & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}

\vspace{1cm}

\begin{longtable}{@{\extracolsep{\fill}}llrlrr@{\extracolsep{0pt}}}
  \textbf{<?lsmb text(''Number'') ?>} & \textbf{<?lsmb text(''Description'') ?>} 
  & \textbf{<?lsmb text(''Qty'') ?>} &
    \textbf{<?lsmb text(''Unit'') ?>} & \textbf{<?lsmb text(''Price'') ?>} 
   & \textbf{<?lsmb text(''Amount'') ?>} \\
\endhead
<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb qty.${lc} ?> &
  <?lsmb unit.${lc} ?> &
  <?lsmb sellprice.${lc} ?> &
  <?lsmb linetotal.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\parbox{\textwidth}{
\rule{\textwidth}{2pt}

\vspace{0.2cm}

\hfill
\begin{tabularx}{7cm}{Xr@{\hspace{1cm}}r@{}}
  & Subtotal & <?lsmb subtotal ?> \\
<?lsmb FOREACH tax ?>
<?lsmb lc = loop.count - 1 ?>
  & <?lsmb taxdescription.${lc} ?> on <?lsmb taxbase.${lc} ?> & <?lsmb tax.${lc} ?>\\
<?lsmb END ?>
  \hline
  & Total & <?lsmb ordtotal ?>\\
\end{tabularx}

\vspace{0.3cm}

\hfill
  <?lsmb text(''All prices in [_1].'', currency) ?>

\vspace{12pt}

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>

}


%\renewcommand{\thefootnote}{\fnsymbol{footnote}}

%\footnotetext[1]{\tiny }

\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (29, 'bin_list', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Bin List'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>

  <tr>
    <td width=10>&nbsp;</td>
    
    <th colspan=3>
      <h4 style="text-transform:uppercase">
         <?lsmb text(''Bin List'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
	<tr bgcolor=000000>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''From'') ?>
          </th>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''Ship To'') ?>
          </th>
	</tr>

	<tr valign=top>
	  <td><?lsmb name ?>
	  <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
          <br><?lsmb address2 ?>
          <?lsmb END ?>
	  <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
          <?lsmb country ?>
          <?lsmb END ?>
	  <br>

	  <?lsmb IF contact ?>
	  <br><?lsmb text(''Attn: [_1]'', contact) ?>
	  <?lsmb END ?>

	  <?lsmb IF vendorphone ?>
	  <br><?lsmb text(''Tel: [_1]'', vendorphone) ?>
	  <?lsmb END ?>

	  <?lsmb IF vendorfax ?>
	  <br><?lsmb text(''Fax: [_1]'', vendorfax) ?>
	  <?lsmb END ?>

	  <?lsmb IF email ?>
	  <br><?lsmb email ?>
	  <?lsmb END ?>
	  
	  </td>
	  
	  <td><?lsmb shiptoname ?>
	  <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
          <br><?lsmb shiptoaddress2 ?>
          <?lsmb END ?>
	  <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
	  <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
          <?lsmb shiptocountry ?>
          <?lsmb END ?>

	  <br>
	  <?lsmb IF shiptocontact ?>
	  <br><?lsmb text(''Attn: [_1]'', shiptocontact) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF shiptophone ?>
	  <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
	  <?lsmb END ?>

	  <?lsmb IF shiptofax ?>
	  <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
	  <?lsmb END ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% border=1>
	<tr>
	  <th width=17% align=left nowrap><?lsmb text(''Order #'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Date'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Contact'') ?></th>
	  <?lsmb IF warehouse ?>
	  <th width=17% align=left nowrap><?lsmb text(''Warehouse'') ?></th>
	  <?lsmb END ?>
	  <th width=17% align=left><?lsmb text(''Shipping Point'') ?></th>
	  <th width=15% align=left><?lsmb text(''Ship via'') ?></th>
	</tr>

	<tr>
	  <td><?lsmb ordnumber ?>&nbsp;</td>
	  
	  <?lsmb IF shippingdate ?>
	  <td><?lsmb shippingdate ?></td>
	  <?lsmb ELSE ?>
	  <td><?lsmb orddate ?></td>
	  <?lsmb END ?>
	  
	  <td><?lsmb employee ?>&nbsp;</td>

	  <?lsmb IF warehouse ?>
	  <td><?lsmb warehouse ?></td>
	  <?lsmb END ?>
  
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=left><font color=ffffff><?lsmb text(''Item'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Serialnumber'') ?></th>
	  <th>&nbsp;</th>
	  <th><font color=ffffff><?lsmb text(''Qty'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Recd'') ?></th>
	  <th>&nbsp;</th>
	  <th><font color=ffffff><?lsmb text(''Bin'') ?></th>
	</tr>

	<?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
	  <td><?lsmb runningnumber.${loop_count} ?></td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td><?lsmb serialnumber.${loop_count} ?></td>
	  <td><?lsmb deliverydate.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td align=right><?lsmb ship.${loop_count} ?></td>
	  <td><?lsmb unit.${loop_count} ?></td>
	  <td><?lsmb bin.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td><hr noshade></td>
  </tr>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (3, 'pos_invoice', NULL, '<?lsmb company FILTER format(''%-40.40s'') ?>
<?lsmb address FILTER format(''%-40.40s'') ?>

Till: <?lsmb till FILTER format(''%-3.3s'') ?>         Phone#: <?lsmb tel ?>
Cashier: <?lsmb employee ?>
Inv #/Date: <?lsmb invnumber ?> / <?lsmb invdate ?>
Printed: <?lsmb dateprinted ?>

  Qty Description                 Amount
<?lsmb FOREACH number ?><?lsmb loop_count = loop.count - 1 ?>
<?lsmb qty FILTER format(''%5.5s'') ?>       <?lsmb description.loop_count FILTER format(''%-18.18s'') ?> <?lsmb linetotal.loop_count FILTER format(''%9.9s'') ?>
      <?lsmb number.loop_count ?> @ <?lsmb sellprice.loop_count ?>/<?lsmb unit.loop_count ?>
<?lsmb END # number ?>

Number of items: <?lsmb totalqty ?>
<?lsmb IF taxincluded ?>
                         ---------------
                        Total: <?lsmb invtotal FILTER format(''%9.9s'') ?>
<?lsmb ELSE ?>
                            ------------
                     Subtotal: <?lsmb subtotal FILTER format(''%9.9s'') ?>
<?lsmb END # taxincluded ?>
<?lsmb FOREACH tax ?><?lsmb loop_count = loop.count - 1 ?>
<?lsmb taxdescription.loop_count FILTER format(''%-23.23s'') ?> @ <?lsmb taxrate.loop_count FILTER format(''%2.2s'') ?>%: <?lsmb tax.loop_count FILTER format(''%9.9s'') ?>
<?lsmb END # tax ?>
<?lsmb FOREACH payment ?><?lsmb loop_count = loop.count - 1 ?>
                         Paid: <?lsmb payment.loop_count FILTER format(''%9.9s'') ?> <?lsmb currency.loop_count ?>
<?lsmb END # payment ?>
<?lsmb IF change ?>
                       Change: <?lsmb change FILTER format(''%9.9s'') ?>
<?lsmb END # change ?>
<?lsmb IF total ?>
                  Balance Due: <?lsmb total FILTER format(''%9.9s'') ?>
<?lsmb END # total ?>
<?lsmb IF discount ?>

<?lsmb discount ?> % Discount applied
<?lsmb END # discount ?>

   Thank you for your valued business!

<?lsmb IF taxincluded ?>
Taxes are included in price.
<?lsmb END # taxincluded ?>
', 'txt');
INSERT INTO template VALUES (32, 'request_quotation', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Request for Quotation'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>
  
    <th colspan=3>
      <h4 style="text-transform:uppercase">
        <?lsmb text(''Request for Quotation'') ?><h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''To:'') ?>
         </th>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''Ship To:'') ?>
         </th>
	</tr>

	<tr valign=top>
	  <td><?lsmb name ?>
	  <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
	  <br><?lsmb address2 ?>
	  <?lsmb END ?>
	  <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
          <br>
	  
	  <?lsmb IF contact ?>
	  <br><?lsmb text(''Attn: [_1]'', contact) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF vendorphone ?>
	  <br><?lsmb text(''Tel: [_1]'', vendorphone) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF vendorfax ?>
	  <br><?lsmb text(''Fax: [_1]'', vendorfax) ?>
	  <?lsmb END ?>
	  </td>

	  <td><?lsmb shiptoname ?>
	  <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
	  <br><?lsmb shiptoaddr2 ?>
	  <?lsmb END ?>
	  <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
	  <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
	  <br><?lsmb shiptocountry ?>
	  <?lsmb END ?>
          <br>

	  <?lsmb IF shiptocontact ?>
	  <br><?lsmb text(''Attn: [_1]'', shiptocontact) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF shiptophone ?>
	  <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
	  <?lsmb END ?>
	  
	  <?lsmb IF shiptofax ?>
	  <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
	  <?lsmb END ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% border=1>
	<tr>
	  <th width=17% align=left><?lsmb text(''RFQ #'') ?></th>
	  <th width=17% align=left><?lsmb text(''Date'') ?></th>
	  <th width=17% align=left><?lsmb text(''Required by'') ?></th>
	  <th width=17% align=left><?lsmb text(''Contact'') ?></th>
	  <th width=17% align=left><?lsmb text(''Shipping Point'') ?></th>
	  <th width=15% align=left><?lsmb text(''Ship via'') ?></th>
	</tr>

	<tr>
	  <td><?lsmb quonumber ?></td>
	  <td><?lsmb quodate ?></td>
	  <td><?lsmb reqdate ?>&nbsp;</td>
	  <td><?lsmb employee ?></td>
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height="10"></tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td><?lsmb text(''Please provide price and delivery time for the following items:'') ?></td>
  </tr>

  <tr height="10"></tr>

  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr>
	  <th align=right><?lsmb text(''Item'') ?></th>
	  <th align=left><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th><?lsmb text(''Qty'') ?></th>
	  <th>&nbsp;</th>
	  <th><?lsmb text(''Delivery'') ?></th>
	  <th<?lsmb text(''Unit Price'') ?></th>
	  <th<?lsmb text(''Extended'') ?></th>
	</tr>

        <?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
        <tr valign=top>
          <td align=right><?lsmb runningnumber.${loop_count} ?>.</td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td><?lsmb unit.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

	<tr>
	  <td colspan=8><hr noshade></td>
	</tr>
	
      </table>
    </td>
  </tr>

  <?lsmb IF notes ?>
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr valign=top>
	  <td<?lsmb text(''Notes'') ?></td>
          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
	</tr>

      </table>
    </td>
  </tr>
  <?lsmb END ?>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (40, 'check_base', NULL, '<?lsmb BLOCK check_single ?>
\parbox[t]{12cm}{
  <?lsmb company ?>

  <?lsmb address ?>}
\hfill
\parbox[t]{6cm}{\hfill <?lsmb source ?>}

\vspace*{0.6cm}

<?lsmb text_amount ?> \dotfill <?lsmb decimal ?>/100 \makebox[0.5cm]{\hfill}

\vspace{0.5cm}

\hfill <?lsmb datepaid ?> \makebox[2cm]{\hfill} <?lsmb 
format_amount({amount = amount, format = ''1,000.00'', money = 1}) ?>

% different date format for datepaid
% <?lsmb DD ?><?lsmb MM ?><?lsmb YYYY ?>

\vspace{0.5cm}

<?lsmb legal_name ?>

<?lsmb street1 ?>

<?lsmb street2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END # state ?>

<?lsmb mail_code ?>

<?lsmb country ?>

\vspace{1.8cm}

<?lsmb memo ?>

\vspace{0.8cm}

<?lsmb company ?>

\vspace{0.5cm}

<?lsmb name ?> \hfill <?lsmb datepaid ?> \hfill <?lsmb source ?>

\vspace{0.5cm}
\begin{tabularx}{\textwidth}{lXrr@{}}
\textbf{<?lsmb text(''Invoice #'') ?>} & \textbf{<?lsmb text(''Invoice Date'') ?>}
  & \textbf{<?lsmb text(''Amount Due'') ?>} & \textbf{<?lsmb text(''Applied'') ?>} \\
<?lsmb FOR inv = invoices ?>
<?lsmb inv.invnumber ?> & <?lsmb inv.invdate ?> \dotfill
  & <?lsmb inv.due ?> & <?lsmb inv.paid ?> \\
<?lsmb END # FOREACH inv ?>
\end{tabularx}

\vspace{1cm}

<?lsmb memo ?>

\vfill
<?lsmb message ?>
<?lsmb END # BLOCK ?>
', 'tex');
INSERT INTO template VALUES (17, 'timecard', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>

\centerline{\textbf{\MakeUppercase{<?lsmb text(''Time Card'') ?>}}}

\vspace*{0.5cm}

\begin{tabular}[t]{ll}
  \textbf{<?lsmb text(''Employee'') ?>} & <?lsmb employee ?> \\
  \textbf{<?lsmb text(''ID'') ?>} & <?lsmb employee_id ?> \\
\end{tabular}
\hfill
\begin{tabular}[t]{ll}
  \textbf{<?lsmb text(''Card ID'') ?>} & <?lsmb id ?> \\
  \textbf{<?lsmb text(''Date'') ?>} & <?lsmb transdate ?> \\
  \textbf{<?lsmb text(''In'') ?>} & <?lsmb checkedin ?> \\
  \textbf{<?lsmb text(''Out'') ?>} & <?lsmb checkedout ?> \\
  \textbf{<?lsmb text(''Hours'') ?>} & <?lsmb qty ?> \\
\end{tabular}

\vspace{1cm}

\begin{tabular}[b]{ll}
  \textbf{<?lsmb text(''Job/Project #'') ?>} & <?lsmb projectnumber ?> \\
  \textbf{<?lsmb text(''Description'') ?>} & <?lsmb projectdescription ?> \\
  \textbf{<?lsmb text(''Labor/Service Code'') ?>} & <?lsmb partnumber ?> \\
  \textbf{<?lsmb text(''Description'') ?>} & <?lsmb description ?> \\
\end{tabular}
\hfill
\begin{tabular}[b]{lr}
  \textbf{<?lsmb text(''Rate'') ?>} & <?lsmb sellprice ?> \\
  \textbf{<?lsmb text(''Total'') ?>} & <?lsmb total ?> \\
\end{tabular}
  
\vspace{0.3cm}

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>
 
\end{document}
<?lsmb END ?>
', 'tex');
INSERT INTO template VALUES (18, 'pick_list', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Pick List'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>

  <tr>
    <td width=10>&nbsp;</td>
    
    <th colspan=3>
      <h4 style="text-transform:uppercase">
          <?lsmb text(''Pick List'') ?>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
        <tr bgcolor=000000>
	  <th width=50% align=left><font color=ffffff><?lsmb text(''Ship To:'')
          ?></th>
	  <th width="50%">&nbsp;</th>
	</tr>

	<tr valign=top>
	  <td><?lsmb shiptoname ?>
	  <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
	  <br><?lsmb shiptoaddress2 ?>
	  <?lsmb END ?>
	  <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
	  <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
	  <br><?lsmb shiptocountry ?>
	  <?lsmb END ?>
	  </td>

	  <td>
	  <?lsmb IF shiptocontact ?>
	  <br><?lsmb text(''Attn: [_1]'', shiptocontact) ?>
	  <?lsmb END ?>

	  <?lsmb IF shiptophone ?>
	  <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
	  <?lsmb END ?>

	  <?lsmb IF shiptofax ?>
	  <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
	  <?lsmb END ?>

	  <?lsmb shiptoemail ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% border=1>
        <tr>
	  <th width=15% align=left><?lsmb text(''Invoice #'') ?></th>
	  <th width=15% align=left><?lsmb text(''Order #'') ?></th>
	  <th width=10% align=left><?lsmb text(''Date'') ?></th>
	  <th width=15% align=left nowrap><?lsmb text(''Contact'') ?></th>
	  <th width=15% align=left><?lsmb text(''Warehouse'') ?></th>
	  <th width=10% align=left><?lsmb text(''Shipping Point'') ?></th>
	  <th width=10% align=left><?lsmb text(''Ship via'') ?></th>
	</tr>

        <tr>
	  <td><?lsmb invnumber ?>&nbsp;</td>
	  <td><?lsmb ordnumber ?>&nbsp;</td>
          <?lsmb IF shippingdate ?>
	  <td><?lsmb shippingdate ?></td>
          <?lsmb ELSE ?>
	  <td><?lsmb transdate ?></td>
	  <?lsmb END ?>

	  <td><?lsmb employee ?>&nbsp;</td>
	  <td><?lsmb warehouse ?>&nbsp;</td>
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=left><font color=ffffff><?lsmb text(''Item'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Qty'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Ship'') ?></th>
	  <th>&nbsp;</th>
	  <th><font color=ffffff><?lsmb text(''Bin'') ?></th>
	</tr>

        <?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
	  <td><?lsmb runningnumber.${loop_count} ?></td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td align=right>[&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]</td>
	  <td><?lsmb unit.${loop_count} ?></td>
	  <td align=right><?lsmb bin.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td><hr noshade></td>
  </tr>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (26, 'printPayment', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title><?lsmb titlebar ?></title>
  <meta http-equiv="Pragma" content="no-cache" />
  <meta http-equiv="Expires" content="-1" />
  <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
  <link rel="stylesheet" href="css/<?lsmb stylesheet ?>" type="text/css" />
  <script language="JavaScript"  src="UI/payments/javascript/maximize_minimize.js"></script>
  <meta http-equiv="content-type" content="text/html; charset=<?lsmb charset ?>" />  
  <meta name="robots" content="noindex,nofollow" />
</head>
<body id="printPayment">
 <?lsmb PROCESS elements.html  # Include form elements helper. ?>
 <?lsmb accountclass.type = ''hidden'';
        INCLUDE input element_data=accountclass ?>
 <?lsmb login.type = ''hidden'' ; INCLUDE input element_data=login ?>
 <?lsmb #WE NEED TO KNOW HOW MANY COLUMNS WE ARE USING, PLEASE DO NOT MOVE THE NEXT LINE -?>
 <?lsmb column_count = 0 -?>
 <table width="100%" id="header_table">
   <tr id="header_bar">
      <th id="top_bar_header" colspan="2" width="30%" align="left">
		<h5>
		LOGO AREA
		<br/><?lsmb text(''Address: [_1]'', company.address) ?>
		<br/><?lsmb text(''Tel: [_1]'', company.telephone) ?>
		</h5>
      </th>
      <th align="left">
     		 <h1 style="text-transform:uppercase">
     		 <?lsmb text(''Payment Order Number [_1]'', header.payment_reference) ?>
     		 </h1>
      </th>
   </tr>
 </table>
 
 <table class="datarow" width="100%" cellspacing="0" cellpadding="0" border="1" bordercolor="000000">
   <tr>
       <th class="titledatarow" align=center width=7%>
       			<font color=000000><?lsmb text(''Invoice'') ?>&nbsp;<?lsmb text(''Number'')?></font>
       </th>
       <th class="titledatarow" align=center width=11%>
       			<font  color=000000><?lsmb text(''Account'') ?></font>
       </th>
       <th class="titledatarow" align=center width=68%>
		       <font color=000000><?lsmb text(''Description'') ?></font>
       </th>
       <th class="titledatarow" align=center width=14%>
       			<font color=000000><?lsmb text(''Source'') ?></font>
       </th>
       <th class="titledatarow" align=center width=14%>
       			<font color=000000><?lsmb text(''Amount'') ?></font>
       </th>
   </tr>
      <?lsmb FOREACH row IN rows -?>
           <tr valign="top">
                 <td align="center"> <?lsmb row.invoice_number ?></td>
                 <td align="center"> <?lsmb row.chart_description?>--<?lsmb row.chart_accno?></td>
                 <td align="center"> <?lsmb row.memo -?>      </td>
                 <td align="center"> <?lsmb row.source ?>            </td>
                 <td align="center"> <?lsmb row.amount ?>            </td>
           </tr>
      <?lsmb END -?>
	  <tr valign="top">
          	<th align="right" colspan="4"> &nbsp; <?lsmb text(''TOTAL'') ?></th>
          	<td align="center"> <?lsmb header.amount ?>     </td>
          </tr>
 </table>
 
 
 <table width=100%>
   <tr>
       <th class="titledatarow" align="left" >
		<font color=000000><?lsmb text(''Currency'') ?>: <?lsmb header.currency ?></font>
       </th>
       <th class="titledatarow" align="left">
       		<font  color=000000><?lsmb text(''Date'') ?>: <?lsmb header.payment_date ?></font>
       </th>
       <th rowspan="5" width="30%" align="left">
       <font size=3 style="text-transform:uppercase">
              <?lsmb text(''Signature'') ?>
              <br></br>
              <br></br>
              <br></br>
              <br>___________________________________________</br>
                  <?lsmb text(''Identification'') ?>

       </font>
       </th>
   </tr>
   <tr>                                                        
     <td width="70%" align="left" colspan="3">
        <font size="3">
                      <b><?lsmb text(''Pay in behalf of'') ?>:</b> <?lsmb header.legal_name ?>
        </font>
     </td>
   </tr>
   <tr>
     <td align="left" colspan="3">
        <font size="3">
                     <b><?lsmb text(''The amount of'') ?>:</b> <?lsmb   header.amount2text  -?>
        </font>
     </td>
   </tr>
   <tr>
     <td align="left" colspan="3">
        <font size="3">
                      <b><?lsmb text(''This document has been approved by'')
        -?>:</b><?lsmb header.employee_first_name -?>&nbsp;<?lsmb  header.employee_last_name -?> 
        </font>
     </td>
   </tr>
   <tr>
       <td colspan="3" align="left">
             <font size="3">
                  <b><?lsmb text(''Approved signature'')?>:</b> ____________________________
            
              </font>
       </td>
   </tr>
   <tr>
       <td align="left" colspan="3">
	      <font size="3"><b><?lsmb text(''Notes'') ?>:</b> <?lsmb header.notes ?></font> 
       </td>
   </tr>
 </table>
 </body>
</html>
', 'html');
INSERT INTO template VALUES (34, 'sales_order', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''Sales Order'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>
    
    <th colspan=3>
      <h4 style="text-transform:uppercase">
          <?lsmb text(''Sales Order'') ?></h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
	<tr bgcolor=000000>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''To'') ?></th>
	  <th align=left width="50%"><font color=ffffff><?lsmb text(''Ship To'') ?>
          </th>
	</tr>

	<tr valign=top>
	  <td><?lsmb name ?>
	  <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
	  <br><?lsmb address2 ?>
	  <?lsmb END ?>
	  <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
          <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
          <br>
	  <?lsmb IF contact ?>
	  <br><?lsmb text(''Attn: [_1]'', contact) ?>
	  <?lsmb END ?>
	  <?lsmb IF customerphone ?>
	  <br><?lsmb text(''Tel: [_1]'', customerphone) ?>
	  <?lsmb END ?>
	  <?lsmb IF customerfax ?>
	  <br><?lsmb text(''Fax: [_1]'', customerfax) ?>
	  <?lsmb END ?>
	  <?lsmb IF email ?>
	  <br><?lsmb email ?>
	  <?lsmb END ?>
	  </td>

	  <td><?lsmb shiptoname ?>
	  <br><?lsmb shiptoaddress1 ?>
	  <?lsmb IF shiptoaddress2 ?>
	  <br><?lsmb shiptoaddress2 ?>
	  <?lsmb END ?>
	  <br><?lsmb shiptocity ?>
	  <?lsmb IF shiptostate ?>
	  , <?lsmb shiptostate ?>
	  <?lsmb END ?>
          <?lsmb shiptozipcode ?>
	  <?lsmb IF shiptocountry ?>
	  <br><?lsmb shiptocountry ?>
	  <?lsmb END ?>
	  <br>
          <?lsmb IF shiptocontact ?>
          <br><?lsmb shiptocontact ?>
          <?lsmb END ?>
	  <?lsmb IF shiptophone ?>
	  <br><?lsmb text(''Tel: [_1]'', shiptophone) ?>
	  <?lsmb END ?>
	  <?lsmb IF shiptofax ?>
	  <br><?lsmb text(''Fax: [_1]'', shiptofax) ?>
	  <?lsmb END ?>
	  <?lsmb IF shiptoemail ?>
	  <br><?lsmb shiptoemail ?>
	  <?lsmb END ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <table width=100% border=1>
	<tr>
	  <th width=17% align=left nowrap><?lsmb text(''Order #'') ?></th>
	  <th width=17% align=left><?lsmb text(''Order Date'') ?></th>
	  <th width=17% align=left><?lsmb text(''Required by'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Salesperson'') ?></th>
	  <th width=17% align=left nowrap><?lsmb text(''Shipping Point'') ?></th>
	  <th width=15% align=left nowrap><?lsmb text(''Ship Via'') ?></th>
	</tr>

	<tr>
	  <td><?lsmb ordnumber ?></td>
	  <td><?lsmb orddate ?></td>
	  <td><?lsmb reqdate ?></td>
	  <td><?lsmb employee ?></td>
	  <td><?lsmb shippingpoint ?>&nbsp;</td>
	  <td><?lsmb shipvia ?>&nbsp;</td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
 
    <td>
      <table width="100%">
	<tr bgcolor=000000>
	  <th align=right><font color=ffffff><?lsmb text(''Item'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Number'') ?></th>
	  <th align=left><font color=ffffff><?lsmb text(''Description'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Qty'') ?></th>
	  <th>&nbsp;</th>
	  <th><font color=ffffff><?lsmb text(''Price'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Disc %'') ?></th>
	  <th><font color=ffffff><?lsmb text(''Amount'') ?></th>
	</tr>

	<?lsmb FOREACH number ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
          <td align=right><?lsmb runningnumber.${loop_count} ?>.</td>
	  <td><?lsmb number.${loop_count} ?></td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td align=right><?lsmb qty.${loop_count} ?></td>
	  <td><?lsmb unit.${loop_count} ?></td>
	  <td align=right><?lsmb sellprice.${loop_count} ?></td>
	  <td align=right><?lsmb discountrate.${loop_count} ?></td>
	  <td align=right><?lsmb linetotal.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

	<tr>
	  <td colspan=8><hr noshade></td>
	</tr>
	
	<tr>
	  <?lsmb IF taxincluded ?>
	  <th colspan=6 align=right><?lsmb text(''Total'') ?></th>
	  <td colspan=2 align=right><?lsmb invtotal ?></td>
	  <?lsmb ELSE ?>
	  <th colspan=6 align=right><?lsmb text(''Subtotal'') ?></th>
	  <td colspan=2 align=right><?lsmb subtotal ?></td>
	  <?lsmb END ?>
	</tr>

	<?lsmb FOREACH tax ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr>
	  <th colspan=6 align=right><?lsmb taxdescription.${loop_count} ?> on <?lsmb taxbase.${loop_count} ?> @ <?lsmb taxrate.${loop_count} ?> %</th>
	  <td colspan=2 align=right><?lsmb tax.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

	<tr>
	  <td colspan=4>&nbsp;</td>
	  <td colspan=4><hr noshade></td>
	</tr>

	<tr>
	  <td colspan=4>
          <?lsmb text_amount ?> ***** <?lsmb decimal ?>/100
	  <?lsmb IF terms ?>
	  <br><?lsmb text(''Terms Net [_1] days'', terms) ?>
	  <?lsmb END ?>
	  </td>
	  <th colspan=2 align=right><?lsmb text(''Total'') ?></th>
	  <th colspan=2 align=right><?lsmb ordtotal ?></th>
	</tr>
	
	<tr>
	  <td>&nbsp;</td>
	</tr>

      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width="100%">
	<tr valign=top>
	  <?lsmb IF notes ?>
	  <td><?lsmb text(''Notes'') ?></td>
          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
	  <?lsmb END ?>
	  <td align=right nowrap>
	  <?lsmb text(''All prices in [_1] Funds'', currency) ?>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width="100%">
	<tr valign=top>
	  <td width="60%"><font size=-3>
	  <?lsmb text(''Special order items are subject to a 10% order cancellation fee.'') ?>
	  </font>
	  </td>
	  <td width="40%">
	  X <hr noshade>
	  </td>
	</tr>
      </table>
    </td>
  </tr>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (35, 'ap_transaction', NULL, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title><?lsmb text(''AP Transaction'') ?></title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body bgcolor=ffffff>

<table width="100%">

  <?lsmb INCLUDE letterhead.html ?>
  
  <tr>
    <td width=10>&nbsp;</td>

    <th colspan=3>
      <h4 style="text-transform:uppercase">
             <?lsmb text(''AP Transaction'') ?>
      </h4>
    </th>
  </tr>

  <tr>
    <td>&nbsp;</td>

    <td>
      <table width=100% cellspacing=0 cellpadding=0>
        <tr valign=top>
          <td><?lsmb name ?>
          <br><?lsmb address1 ?>
	  <?lsmb IF address2 ?>
          <br><?lsmb address2 ?>
	  <?lsmb END ?>
          <br><?lsmb city ?>
	  <?lsmb IF state ?>
	  , <?lsmb state ?>
	  <?lsmb END ?>
	  <?lsmb zipcode ?>
	  <?lsmb IF country ?>
	  <br><?lsmb country ?>
	  <?lsmb END ?>
          <br>

          <?lsmb IF contact ?>
          <br><?lsmb contact ?>
          <br>
          <?lsmb END ?>

          <?lsmb IF vendorphone ?>
          <br><?lsmb text(''Tel: [_1]'', vendorphone) ?>
          <?lsmb END ?>

          <?lsmb IF vendorfax ?>
          <br><?lsmb text(''Fax: [_1]'', vendorfax) ?>
          <?lsmb END ?>

          <?lsmb IF email ?>
          <br><?lsmb email ?>
          <?lsmb END ?>

          <?lsmb IF vendortaxnumber ?>
          <p><?lsmb text(''Taxnumber: [_1]'', vendortaxnumber) ?>
          <?lsmb END ?>
          </td>
   
	  <td align=right>
	    <table>
	      <tr>
		<th align=left nowrap><?lsmb text(''Invoice #'') ?></th>
		<td><?lsmb invnumber ?></td>
	      </tr>
	      <tr>
		<th align=left nowrap><?lsmb text(''Date'') ?></th>
		<td><?lsmb invdate ?></td>
	      </tr>
	      <tr>
		<th align=left nowrap><?lsmb text(''Due'') ?></th>
		<td><?lsmb duedate ?></td>
	      </tr>
	      <?lsmb IF ponumber ?>
              <tr>
                <th align=left><?lsmb text(''PO #'') ?></th>
		<td><?lsmb ponumber ?>&nbsp;</td>
	      </tr>
	      <?lsmb END ?>
	      <?lsmb IF ordnumber ?>
	      <tr>
		<th align=left><?lsmb text(''Order #'') ?></th>
		<td><?lsmb ordnumber ?>&nbsp;</td>
	      </tr>
	      <?lsmb END ?>
	      <tr>
		<th align=left nowrap><?lsmb text(''Employee'') ?></th>
		<td><?lsmb employee ?>&nbsp;</td>
	      </tr>
	    </table>
	  </td>
        </tr>
      </table>
    </td>
  </tr>

  <tr height=5></tr>
  
  <tr>
    <td>&nbsp;</td>
  
    <td>
      <table>
	<?lsmb FOREACH account ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr valign=top>
	  <td><?lsmb accno.${loop_count} ?></td>
	  <td><?lsmb account.${loop_count} ?></td>
	  <td width=10> </td>
	  <td align=right><?lsmb amount.${loop_count} ?></td>
	  <td width=10> </td>
	  <td><?lsmb description.${loop_count} ?></td>
	  <td width=10> </td>
	  <td><?lsmb projectnumber.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>

	<tr>
	  <?lsmb IF taxincluded ?>
	  <th colspan=2 align=right><?lsmb text(''Total'') ?></th>
	  <td width=10> </td>
	  <td align=right><?lsmb invtotal ?></td>
	  <?lsmb ELSE ?>
	  <th colspan=2 align=right><?lsmb text(''Subtotal'') ?></th>
	  <td width=10> </td>
	  <td align=right><?lsmb subtotal ?></td>
	  <?lsmb END ?>
	</tr>

	<?lsmb FOREACH tax ?>
	<?lsmb loop_count = loop.count - 1 ?>
	<tr>
	  <th colspan=2 align=right><?lsmb taxdescription.${loop_count} ?> @ <?lsmb taxrate.${loop_count} ?> %</th>
	  <td width=10> </td>
	  <td align=right><?lsmb tax.${loop_count} ?></td>
	</tr>
	<?lsmb END ?>
	
	<?lsmb IF NOT taxincluded ?>
	<tr>
	  <th colspan=2 align=right><?lsmb text(''Total'') ?></th>
	  <td width=10> </td>
	  <td align=right><?lsmb invtotal ?></td>
	</tr>
	<?lsmb END ?>
      </table>
    </td>
  </tr>
  
  <tr>
    <td>&nbsp;</td>
    
    <td>
      <?lsmb text_amount ?> ***** <?lsmb decimal ?>/100 <?lsmb currency ?>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>

          <td><?lsmb  FOREACH P IN notes.split(''\n\n'') ?>
                    <p><?lsmb P ?></p>
               <?lsmb END ?></td>
  </tr>

  <?lsmb IF paid_1 ?>
  <tr>
    <td>&nbsp;</td>

    <td>
      <table>
        <tr>
          <th><?lsmb text(''Payments'') ?></th>
        </tr>

        <tr>
          <td>
          <hr noshade>
          </td>
        </tr>

	<tr>
	  <td>
	    <table>
	      <tr>
		<th><?lsmb text(''Date'') ?></th>
		<th>&nbsp;</th>
		<th><?lsmb text(''Source'') ?></th>
		<th><?lsmb text(''Memo'') ?></th>
		<th><?lsmb text(''Amount'') ?></th>
	      </tr>
  <?lsmb END ?>

        <?lsmb FOREACH payment ?>
        <?lsmb loop_count = loop.count - 1 ?>
	      <tr>
		<td><?lsmb paymentdate.${loop_count} ?></td>
		<td><?lsmb paymentaccount.${loop_count} ?></td>
		<td><?lsmb paymentsource.${loop_count} ?></td>
		<td><?lsmb paymentmemo.${loop_count} ?></td>
		<td align=right><?lsmb payment.${loop_count} ?></td>
	      </tr>
        <?lsmb END ?>

  <?lsmb IF paid_1 ?>
	    </table>
	  </td>
        </tr>
      </table>
    </td>
  </tr>
  <?lsmb END ?>

  <tr height=10></tr>

  <?lsmb IF taxincluded ?>
  <tr>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <th colspan=3 align=left><font size=-2>
          <?lsmb text(''Taxes shown are included in price.'') ?></th>
  </tr>
  <?lsmb END ?>

</table>

</body>
</html>

', 'html');
INSERT INTO template VALUES (41, 'request_quotation', NULL, '<?lsmb FILTER latex -?>
\documentclass{scrartcl}
 \usepackage{xltxtra}
 \usepackage{fontspec}
 \setmainfont{LiberationSans-Regular.ttf}
\usepackage{tabularx}
\usepackage{longtable}
\setlength\LTleft{0pt}
\setlength\LTright{0pt}
\usepackage[letterpaper,top=2cm,bottom=1.5cm,left=1.1cm,right=1.5cm]{geometry}
\usepackage{graphicx}

\begin{document}

\pagestyle{myheadings}
\thispagestyle{empty}

<?lsmb INCLUDE letterhead.tex ?>


\markboth{<?lsmb company ?>\hfill <?lsmb ordnumber ?>}{<?lsmb company ?>\hfill <?lsmb ordnumber ?>}


\vspace*{0.5cm}

\parbox[t]{.5\textwidth}{
\textbf{<?lsmb text(''To'') ?>}
\vspace{0.3cm}
  
<?lsmb name ?>

<?lsmb address1 ?>

<?lsmb address2 ?>

<?lsmb city ?>
<?lsmb IF state ?>
\hspace{-0.1cm}, <?lsmb state ?>
<?lsmb END ?>
<?lsmb zipcode ?>

<?lsmb country ?>

\vspace{0.3cm}

<?lsmb IF contact ?>
<?lsmb contact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF vendorphone ?>
<?lsmb text(''Tel: [_1]'', vendorphone) ?>
<?lsmb END ?>

<?lsmb IF vendorfax ?>
<?lsmb text(''Fax: [_1]'', vendorfax) ?>
<?lsmb END ?>

<?lsmb email ?>
}
\parbox[t]{.5\textwidth}{
\textbf{Ship To}
\vspace{0.3cm}

<?lsmb shiptoname ?>

<?lsmb shiptoaddress1 ?>

<?lsmb shiptoaddress2 ?>

<?lsmb shiptocity ?>
<?lsmb IF shiptostate ?>
\hspace{-0.1cm}, <?lsmb shiptostate ?>
<?lsmb END ?>
<?lsmb shiptozipcode ?>

<?lsmb shiptocountry ?>

\vspace{0.3cm}

<?lsmb IF shiptocontact ?>
<?lsmb shiptocontact ?>
\vspace{0.2cm}
<?lsmb END ?>

<?lsmb IF shiptophone ?>
<?lsmb text(''Tel: [_1]'', shiptophone) ?>
<?lsmb END ?>

<?lsmb IF shiptofax ?>
<?lsmb text(''Fax: [_1]'', shiptofax) ?>
<?lsmb END ?>

<?lsmb shiptoemail ?>
}
\hfill

\vspace{1cm}

\textbf{\MakeUppercase{<?lsmb text(''Request for Quotation'') ?>}}
\hfill

\vspace{1cm}

\begin{tabularx}{\textwidth}{*{6}{|X}|} \hline
  \textbf{<?lsmb text(''RFQ #'') ?>} & \textbf{<?lsmb text(''Date'') ?>} 
  & \textbf{<?lsmb text(''Required by'') ?>} & \textbf{<?lsmb text(''Contact'') ?>} 
  & \textbf{<?lsmb text(''Shipping Point'') ?>} 
  & \textbf{<?lsmb text(''Ship via'') ?>} \\ [0.5ex]
  \hline
  <?lsmb quonumber ?> & <?lsmb quodate ?> & <?lsmb reqdate ?> & <?lsmb employee ?> & <?lsmb shippingpoint ?> & <?lsmb shipvia ?> \\
  \hline
\end{tabularx}

\vspace{1cm}

<?lsmb text(''Please provide price and delivery time for the following items:'') ?>

\vspace{1cm}

\begin{longtable}{@{\extracolsep{\fill}}lcrllrr@{\extracolsep{\fill}}}
  \textbf{<?lsmb text(''Number'') ?>} & \textbf{<?lsmb text(''Description'') ?>} 
  & \textbf{<?lsmb text(''Qty'') ?>} & & \textbf{<?lsmb text(''Delivery'') ?>} 
  & \textbf{<?lsmb text(''Unit Price'') ?>} & \textbf{<?lsmb text(''Extended'') ?>} 
\endhead
<?lsmb FOREACH number ?>
<?lsmb lc = loop.count - 1 ?>
  <?lsmb number.${lc} ?> &
  <?lsmb description.${lc} ?> &
  <?lsmb qty.${lc} ?> &
  <?lsmb unit.${lc} ?> \\
<?lsmb END ?>
\end{longtable}


\parbox{\textwidth}{
\rule{\textwidth}{2pt}

\hfill

<?lsmb FOREACH P IN notes.split(''\n\n'') ?>
<?lsmb P ?>\medskip

<?lsmb END ?>

}

\end{document}
<?lsmb END ?>
', 'tex');


--
-- Name: template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('template_id_seq', 41, true);


--
-- PostgreSQL database dump complete
--

