-- Table function definition.
-- Using the CSV file of all PTFs for a Version
-- get that file and populate a temp file.
-- in that temp file add the current status of each PTF.
-- replace Your_fav_lib with a real library
-  Kudos to https://github.com/ryan-moeller21 for helping make this Function



CREATE or replace function Your_Fav_Lib.FIND_LOADED_PTFS (
 VerRelMod CHAR(3) CCSID 37 DEFAULT '750'
)
    RETURNS TABLE (
        PRODUCT CHAR(7) CCSID 37,
        OSRELEASE CHAR(6) CCSID 37,
        PTF CHAR(7) CCSID 37,
        LOAD_sts varCHAR(30) CCSID 37,
        PKG CHAR(6) CCSID 37,
        AVAILDATE DATE,
        MRIFEATURE CHAR(4) CCSID 37,
        REPLACEDBY CHAR(7) CCSID 37,
        CATEGORIES CHAR(3) CCSID 37,
        ABSTRACT varCHAR(75) CCSID 37
    )
    LANGUAGE SQL                                                                   
    MODIFIES SQL DATA                                                              
    NOT DETERMINISTIC                                                              
    NOT FENCED                                                                     
    EXTERNAL ACTION                                                                  
    SET OPTION COMMIT=*NONE, MONITOR=*SYSTEM, USRPRF=*USER, DYNUSRPRF=*USER        
   BEGIN
     declare Target_URL varchar(250) FOR SBCS DATA;
     set Target_URL = 'https://public.dhe.ibm.com/services/us/igsc/PSP/SF97' concat VerRelMod concat '.csv'; 
   --DEBUG  call systools.lprintf(Target_URL) ;
        CALL QSYS2.IFS_WRITE_UTF8(
            PATH_NAME => '/tmp/TEMP_ALL_PTFs.csv',
            OVERWRITE => 'REPLACE',
            END_OF_LINE => 'CRLF',
            LINE => (SELECT RESPONSE_MESSAGE
                        FROM TABLE (
                          QSYS2.HTTP_GET_VERBOSE(URL => Target_URL, OPTIONS => '{"sslTolerate":"TRUE"}')
                            ))
        );
        CREATE OR REPLACE TABLE QTEMP.I_ALL_PTFs (
                    PRODUCT CHAR(7) CCSID 37 NOT NULL DEFAULT '',
                    OSRELEASE CHAR(6) CCSID 37 NOT NULL DEFAULT '',
                    PTF CHAR(7) CCSID 37 NOT NULL DEFAULT '',
                    PKG CHAR(6) CCSID 37 NOT NULL DEFAULT '',
                    AVAILDATE DATE NOT NULL DEFAULT CURRENT_DATE,
                    MRIFEATURE CHAR(4) CCSID 37 NOT NULL DEFAULT '',
                    REPLACEDBY CHAR(7) CCSID 37 NOT NULL DEFAULT '',
                    CATEGORIES CHAR(3) CCSID 37 NOT NULL DEFAULT '',
                    ABSTRACT varCHAR(75) CCSID 37 NOT NULL DEFAULT ''
                )
            ON REPLACE DELETE ROWS;
        CALL QSYS2.QCMDEXC('CPYFRMIMPF FROMSTMF(''/tmp/TEMP_ALL_PTFs.csv'') TOFILE(QTEMP/I_ALL_PTFs) MBROPT(*REPLACE) RCDDLM(*LF) STRDLM(*NONE) RMVBLANK(*BOTH) RPLNULLVAL(*FLDDFT) RMVCOLNAM(*YES)');
    
    RETURN SELECT 
               i.PRODUCT,
               i.OSRELEASE,
               i.PTF,
               trim(COALESCE((SELECT PI.PTF_LOADED_STATUS
                           FROM QSYS2.PTF_INFO PI
                           WHERE i.PRODUCT = PI.PTF_PRODUCT_ID
                             AND i.PTF = PI.PTF_IDENTIFIER),
                   'NOT ON SYSTEM')) AS LOAD_status,
               i.PKG,
               i.AVAILDATE,
               i.MRIFEATURE,
               i.REPLACEDBY,
               i.CATEGORIES,
               i.ABSTRACT
            FROM QTEMP.I_ALL_PTFs i
            WHERE i.PTF > ' '
            ORDER BY i.AVAILDATE DESC;
    
    END;

-- Select from table function
SELECT Product       ,Osrelease ,Ptf
       ,Load_Sts     ,Pkg       ,Availdate
       ,Replacedby   ,Abstract  ,Mrifeature
       ,Categories
    FROM TABLE ( Your_Fav_Lib.FIND_LOADED_PTFS('750') );

    
