begin
CALL QSYS2.IFS_WRITE_UTF8(
  PATH_NAME => '/tmp/TEMP_sf97750.csv'
 ,OVERWRITE => 'REPLACE'
 ,END_OF_LINE => 'CRLF'
 ,LINE => (select response_message from table( QSYS2.HTTP_GET_verbose(
      URL     => 'https://public.dhe.ibm.com/services/us/igsc/PSP/SF97750.csv',     
      OPTIONS => '{"sslTolerate":"TRUE"}')
)));

CREATE or replace TABLE qtemp.SF97750 ( 
	PRODUCT CHAR(7) CCSID 37 NOT NULL DEFAULT '' , 
	OSRELEASE CHAR(6) CCSID 37 NOT NULL DEFAULT '' , 
	PTF CHAR(7) CCSID 37 NOT NULL DEFAULT '' , 
	PKG CHAR(6) CCSID 37 NOT NULL DEFAULT '' , 
	AVAILDATE DATE NOT NULL DEFAULT CURRENT_DATE , 
	MRIFEATURE CHAR(4) CCSID 37 NOT NULL DEFAULT '' , 
	REPLACEDBY CHAR(7) CCSID 37 NOT NULL DEFAULT '' , 
	CATEGORIES CHAR(3) CCSID 37 NOT NULL DEFAULT '' , 
	ABSTRACT CHAR(75) CCSID 37 NOT NULL DEFAULT '' ) ;


call qsys2.qcmdexc('CPYFRMIMPF FROMSTMF(''/tmp/TEMP_sf97750.csv'') TOFILE(QTEMP/SF97750) MBROPT(*REPLACE) RCDDLM(*LF) STRDLM(*NONE) RMVBLANK(*BOTH) RPLNULLVAL(*FLDDFT) RMVCOLNAM(*YES)');
end;

--   Step two.

select a.Product
       ,a.Osrelease
       ,a.Ptf
    ,COALESCE((select b.ptf_loaded_status from QSYS2.PTF_INFO b where a.product = b.Ptf_product_id and a.ptf = b.ptf_identifier), 'NOT ON SYSTEM') as loaded
       ,a.Pkg
       ,a.Availdate
       ,a.Mrifeature
       ,a.Replacedby
       ,a.Categories
       ,a.Abstract from qtemp.sf97750 a
where product > ' '
order by availdate desc
;


end;
