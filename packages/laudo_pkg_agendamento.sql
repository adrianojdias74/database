create or replace package laudo_pkg_agendamento is
    --
    -- PACKAGE CRIADA PARA ROTINAS DE AGENDAMENTO
    -- 04/08/2022
    --
     -- 13/09/2023 não pode subir para produção com esse parametro pidagendamentopericia
    procedure prc_agendamento_protocolo(pprotocolo                in number default null
                                       ,ptipo_agendamento         in varchar2 default null
                                       ,pprontuariopericialoficio in number default null
                                       ,ptriagem                  in varchar2 default null
                                       ,pidagendamentopericia     out number);
    --
    procedure prc_valida_agendamento(pid_oficio	     	         in number
    							                	,pespecialidade  	         in number
                                    ,pnatureza       	         in number
                                    ,praj            	         in number
                                    ,pqtd_periciando           in number
                                    ,psituacao_periciando      in varchar2 default null
                                    ,ptipo_agendamento         in varchar2 default null
                                    ,ppsiquiatria		           in varchar2
                                    ,pprontuariopericialoficio in number default null
                                       ,pcdp                      in number default null
                                   --retorno
                                    ,perro                     out varchar2
                                    ,pexiste_mesma_especinat   out varchar2
                                    ,pidpericiaagendamento     out number);
    --
    function fnc_qtd_periciando_oficio(poficio in number) return number;
    --
    procedure prc_agendar(poficio                   in number
    			 		           ,pprotocolo                in number
                         ,ptipo_agendamento         in varchar2 default null
                         ,ppsiquiatria              in varchar2
                         ,pprontuariopericialoficio in number default null
                         ,pcdp                 in number default null 
                         ,pidpericiaagendamento     out number);
    --
    procedure prc_agendar_sequencia(poficio               in number
    							                 ,pprotocolo            in number
    							                 ,pqtd_periciando       in number
                                   ,ptipo_agendamento     in varchar2 default null
                                   ,ppsiquiatria          in varchar2
                                   ,pcdp                 in number default null 
                                   ,pidpericiaagendamento out number
                                   );
    --
    function fnc_codigo_raj(praj in varchar2) return number;
    --
    function fnc_define_raj(pdescentralizada in varchar2
                           ,praj             in number
                           ,pcomarca         in varchar2) return number;

     function fnc_define_cdp(pcdp in varchar2  ) return number;
                         


    --
    function fnc_valida_hora_agenda (phorainicio in date
                                    ,phorafim    in date
                                    ,pcodperito  in number) return varchar2;
    --
    function fnc_codigo_data_trancada (phorainicio in date
                                      ,phorafim    in date
                                      ,pcodperito  in number) return varchar2;
    --
    procedure prc_tranca_data(pcodperito       in number
                             ,pdatainicio      in date
                             ,pdatafim         in date
                             ,phorainicio      in varchar2
                             ,phorafim         in varchar2
                             ,pmotivo          in number
                             ,pcoddatatrancada in number);
    -- 
    procedure prc_agendamento_prontuario(pprotocolo           in number,
                                         poficio              in number,
                                         pespecialidade       in number,
                                         pnatureza            in number,
                                         praj                 in number,   
                                         pqtdpericiando       in number,
                                         psituacao_periciando in varchar2 default null,
                                         ppsiquiatria         in varchar2,
                                         ptipo_agendamento    in varchar2 default null,
                                         pprontuariopericialoficio in number default null,
                                         pidpericiaagendamento     out number);
    --
    procedure prc_remanejar_agenda(ppericia_agendamento                     in number
    							  ,pperito_agenda_detalhe 		    		in number
    							  ,pperito_remanejar						in number
    							  ,pperito_agenda_detalhe_remanejar 		in number
    							  ,pperito_perfil_remanejar					in number);
    --
    procedure prc_remanejar_agenda_urgente(ppericia_agendamento     in number
    							          ,pperito_agenda_detalhe 	in number
    							          ,pperito_remanejar		in number
                                          ,phorario_inicio          in date
                                          ,pintervalo_atendimento   in number 
    							          ,pperito_perfil_remanejar	in number);
    --
    procedure prc_agendar_psicologia(poficio                in number
                                    ,pprotocolo             in number
    			 		                      ,pperito                in number
    			 		                      ,pdatabase              in date
                                    ,pespecialidadenatureza in number
                                    ,pefetivocadastrado     in varchar2
                                    ,pseqagendamento        in number  default null
                                    ,ptipo_agendamento      in varchar2 default null
                                    ,praj                   in number
                                    ,pcdp                   in number default null);
    --
    function fnc_retorna_qtd_reu (poficio in number) return number;
    --
    function fnc_retorna_protuario_oficio_reu (poficio in number ,pprotocolo in number) return varchar2;
    --
    procedure prc_agendar_urgente(pespecialidade            in number
                                 ,pnatureza                 in number
                                 ,pcodperito                in number
                                 ,ptipo_agendamento         in varchar2
                                 ,pdata_agendamento         in date
                                 ,phorario_inicio           in date
                                 ,phorario_fim              in date default null
                                 ,pintervalo_atendimento    in number default null
                                 ,pprontuariopericialoficio in number
                                 ,preu                      in varchar2
                                 --retorno
                                 ,pidpericiaagendamento     out number);
    --
    procedure prc_agendar_externa(pespecialidade            in number
                                 ,pnatureza                 in number
                                 ,pcodperito                in number
                                 ,ptipo_agendamento         in varchar2
                                 ,pprontuariopericialoficio in number
                                 ,praj_definida             in number
                                 ,pprotocolo                in number
                                 ,preu                      in varchar2
                                 --retorno
                                 ,pidpericiaagendamento     out number);
    --
    procedure prc_valida_psicologia(pespecialidade            in number
                                   ,pnatureza                 in number
                                   ,poficio                   in number
                                   ,ptipo_agendamento         in varchar2
                                   ,pqtdpericiando            in number
                                   ,pcdp                      in number default null
                                   ,pprotocolo                in number
                                   --retorno
                                   ,perro                     out varchar2
                                   ,ppsicologia               out varchar2
                                   ,pvalida                   out varchar2
                                   ,pidpericiaagendamento     out number
      
                                   ,pqtpericiando             out number);
    --
    procedure prc_declaracao_comparecimento(pidprontuariopericial   in number default null
                                           ,ptipo_declaracao        in varchar2 default null
                                           ,pcod_periciando         in number default null
                                           ,pnumero_processo        in varchar2 default null
                                           ,passistente_selecionado in varchar2 default null
                                           ,pnome_acompanhante      in varchar2 default null
                                           ,pdocumento_acompanhante in varchar2 default null
                                           ,pperiodo_inicial        in varchar2 default null);
    --
    procedure prc_termo_consentimento(pcod_periciando         in number default null
                                     ,pnome_acompanhante      in varchar2 default null
                                     ,pdocumento_acompanhante in varchar2 default null); 
    --
    procedure prc_agendar_externa_zona(pespecialidade    in number
                                      ,ptipo_agendamento in varchar2
                                      ,pzona             in varchar2
                                      ,poficio           in number
                                      ,praj              in number
                                      ,pprotocolo        in number
                                      ,pqtd_periciando   in number
                                      --retorno
                                      ,pidpericiaagendamento     out number) ;  
                                      
                                   
    --
    procedure prc_agendamento_aprovacao_diretoria(pprotocolo           in number,
                                                  poficio              in number,
                                                  pespecialidade       in number,
                                                  pnatureza            in number,
                                                  praj                 in number,   
                                                  pqtdpericiando       in number,
                                                  psituacao_periciando in varchar2 default null,
                                                  ppsiquiatria         in varchar2,
                                                  ptipo_agendamento    in varchar2 default null,
                                                  pprontuariopericialoficio in number default null,
                                                  pcodperito           in number,
                                                  pidpericiaagendamento     out number);
    --
    procedure prc_agendar_aprovacao_diretoria(poficio                   in number
                                             ,pprotocolo                in number
                                             ,ptipo_agendamento         in varchar2 default null
                                             ,ppsiquiatria              in varchar2
                                             ,pprontuariopericialoficio in number default null
                                             ,pcdp                      in number default null 
                                             ,pcodperito                in number
                                             ,pidpericiaagendamento     out number);
    --
    procedure prc_valida_agendamento_diretoria(pid_oficio	     	         in number
    							             	,pespecialidade  	         in number
                                    ,pnatureza       	         in number
                                    ,praj            	         in number
                                    ,pqtd_periciando           in number
                                    ,psituacao_periciando      in varchar2 default null
                                    ,ptipo_agendamento         in varchar2 default null
                                    ,ppsiquiatria		           in varchar2
                                    ,pprontuariopericialoficio in number default null
                                       ,pcdp                      in number default null
                                   --retorno
                                    ,perro                     out varchar2
                                    ,pexiste_mesma_especinat   out varchar2
                                    ,pidpericiaagendamento     out number);
end;
/