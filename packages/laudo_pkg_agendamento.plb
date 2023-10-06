create or replace package body laudo_pkg_agendamento is
    --
    -- PACKAGE CRIADA PARA ROTINAS DE AGENDAMENTO
    -- 11/08/2022
    -- 

     V_OFICIO CLOB;  
     v_arquivoAssinado  CLOB;
    --
    cursor c_dados_oficio(poficio in number) is
	  select distinct o.especialidade
	  ,      o.natureza
	  ,	     op.situacaopericiando
	  ,	     o.raj
	  ,		 o.comarcaprocesso
	  ,      o.descentralizada
    ,        o.qtdpericiando
    ,        o.localpericia
    ,        o.local
    ,        o.cdp
    ,        nvl(op.nomelocalprisao,c.descdp) as nomelocalprisao --  ta certo
	  from oficio           o
      ,    oficiopericiando op --está certo?
      left join cdp c on op.codigo_cdp = c.codcdp
	  where op.id_oficio = o.id_oficio
      and o.id_oficio = poficio
      and rownum = 1;
    --  
	vdados_oficio c_dados_oficio%rowtype;
    --
    cursor c_perito_agendamento(pespecialidade in number      
							   ,pnatureza      in number      
      						   ,praj	       in number
                               ,pcdp	       in number default null) is  
	  select pt.codperito
	  ,	   	 p.nompessoa
	  ,	   	 en.codespecialidadenatureza
      ,      case 
               when pt.indefetivo = 'Y' or pt.indcredenciado = 'Y' then 'Y'
               else 'N' 
             end efetivocadastrado
	  from perito 			           pt
	  ,	   pessoaimesc 		 		   pi
	  ,	   pessoa		 		 	   p
	  ,    peritoespecialidade 		   pe
	  ,    peritoespecialidadenatureza pen
	  ,    especialidade			   e
	  ,    natureza				       n
	  ,	   especialidadenatureza       en
	  ,	   peritoperfil				   pp
      ,    peritogeracaoagenda         pga
      ,    peritoagenda                pa
      ,    peritoagendadetalhe         pad
	  where pt.codpessoaimesc                  = pi.codpessoaimesc
      and pt.indativo                          = 'Y'
	    and pi.situacaopessoaimesc             = 'Y'
	    and p.codpessoa      	               = pi.codpessoa
	    and pe.codperito		               = pt.codperito
	    and pe.indativo		                   = 'Y'
	    and pe.codperitoespecialidade          = pen.codperitoespecialidade
	    and e.codespecialidade 		           = pe.codespecialidade
	    and en.codespecialidadenatureza        = pen.codespecialidadenatureza
	    and en.indativo				           = 'Y'
	    and en.codnatureza			           = n.codnatureza
	    and n.codnatureza				       = pnatureza
	    and e.codespecialidade		           = pespecialidade
        and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
	    and pp.codperito  				       = pt.codperito
        and pga.codperitoperfil                = pp.codperitoperfil
        and pga.codperito                      = pp.codperito
        and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
        and pa.codperitoagenda                 = pad.codperitoagenda
        and pa.datatendimento                  = trunc(pad.horinicio)
        and pad.indreservado                   = 'N'
        and pad.indencaixe                     = 'N'
        and pad.indativo                       = 'Y'
        --and pad.horinicio                      > sysdate !!!!  
        and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
	    and ((pp.codraj	= praj  and  praj is not null)   or  (praj is null ))
        and  pcdp                               is null
        union
 
          select pt.codperito
	  ,	   	 p.nompessoa
	  ,	   	 en.codespecialidadenatureza
      ,      case 
               when pt.indefetivo = 'Y' or pt.indcredenciado = 'Y' then 'Y'
               else 'N' 
             end efetivocadastrado
	  from perito 			               pt
	  ,	   pessoaimesc 		 		         pi
	  ,	   pessoa		 		 	             p
	  ,    peritoespecialidade 		     pe
	  ,    peritoespecialidadenatureza pen
	  ,    especialidade			         e
	  ,    natureza				             n
	  ,	   especialidadenatureza       en
	  ,	   peritoperfil				         pp
    ,    peritogeracaoagenda         pga
    ,    peritoagenda                pa
    ,    peritoagendadetalhe         pad
	  where pt.codpessoaimesc                  = pi.codpessoaimesc
      and pt.indativo                        = 'Y'
	    and pi.situacaopessoaimesc             = 'Y'
	    and p.codpessoa      	                 = pi.codpessoa
	    and pe.codperito		                   = pt.codperito
	    and pe.indativo		                     = 'Y'
	    and pe.codperitoespecialidade          = pen.codperitoespecialidade
	    and e.codespecialidade 		             = pe.codespecialidade
	    and en.codespecialidadenatureza        = pen.codespecialidadenatureza
	    and en.indativo				                 = 'Y'
	    and en.codnatureza			               = n.codnatureza
	    and n.codnatureza				               = pnatureza
	    and e.codespecialidade		             = pespecialidade
      and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
	    and pp.codperito  				             = pt.codperito
      and pga.codperitoperfil                = pp.codperitoperfil
      and pga.codperito                      = pp.codperito
      and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
      and pa.codperitoagenda                 = pad.codperitoagenda
      and pa.datatendimento                  = trunc(pad.horinicio)
      and pad.indreservado                   = 'N'
      and pad.indencaixe                     = 'N'
      and pad.indativo                       = 'Y'
        --and pad.horinicio                      > sysdate !!!!  
      and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
	    and pp.codcpd                          = pcdp
        and pcdp                               is not null     
        order by 4  desc; --desc, pt.indcredenciado desc, pt.indcadastrado desc;
	v_perito_agendamento c_perito_agendamento%rowtype;
    --
    cursor c_data_agendamento(pespecialidadenatureza in number
                             ,pperito                in number default null 
                             ,praj		               in number
                             ,pcdp                   in number default null ) is
        select pad.codperitoagendadetalhe
        ,      pad.horinicio
        ,      pad.horfim
        from  peritoagendadetalhe         pad
        ,     peritoagenda                pa
        ,     peritogeracaoagenda         pga
        ,     peritoperfil                pp
        ,     peritoespecialidadenatureza pen
        ,     perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y'  
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.qtdpericiasrestantes            >= 1
          and pa.datatendimento                  = trunc(pad.horinicio) -- LIMITA A PEGAR DATA DENTRO DO RANGE DO MESMO DIA
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.INDATIVO                       = 'Y'
          --and pad.HORINICIO					     > sysdate !!!!
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
          and pga.codperito                      = nvl(pperito,v_perito_agendamento.codperito)
          and pga.codperitoperfil                = pp.codperitoperfil
          and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
          and pen.codespecialidadenatureza       = pespecialidadenatureza
          and pp.codraj                          = praj
          and pcdp                               is null
          and rownum = 1
          union
          select pad.codperitoagendadetalhe
          ,      pad.horinicio
          ,      pad.horfim
          from  peritoagendadetalhe         pad
          ,     peritoagenda                pa
          ,     peritogeracaoagenda         pga
          ,     peritoperfil                pp
          ,     peritoespecialidadenatureza pen
          ,     perito                      pt
          where pp.codperito                       = pt.codperito
            and pt.indativo                        = 'Y' 
            and pa.codperitoagenda                 = pad.codperitoagenda
            and pa.qtdpericiasrestantes            >= 1
            and pa.datatendimento                  = trunc(pad.horinicio) -- LIMITA A PEGAR DATA DENTRO DO RANGE DO MESMO DIA
            and pad.indreservado                   = 'N'
            and pad.indencaixe                     = 'N'
            and pad.INDATIVO                       = 'Y'
            --and pad.HORINICIO					     > sysdate !!!!
            and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                 and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
              or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                  and pad.HORINICIO > sysdate))
            and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
            and pga.codperito                      = nvl(pperito,v_perito_agendamento.codperito)
            and pga.codperitoperfil                = pp.codperitoperfil
            and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
            and pen.codespecialidadenatureza       = pespecialidadenatureza
            and pp.codcpd                          = pcdp
            and pcdp                               is not null
            and rownum = 1
            order by 2 asc;
      vdata_agendamento c_data_agendamento%rowtype;
    --
    cursor c_data_agendamento_reu(pespecialidadenatureza in number,
                                  pdatabase              in date,
                                  praj                   in number,
                                  pperito                in number,
                                  pcdp                   in number default null) is
        select pad.codperitoagendadetalhe
        ,      pad.horinicio
        ,      pad.horfim
        from  peritoagendadetalhe         pad
        ,     peritoagenda                pa
        ,     peritogeracaoagenda         pga
        ,     peritoperfil                pp
        ,     peritoespecialidadenatureza pen
        ,     perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.qtdpericiasrestantes            >= 1
          and pa.datatendimento                  = trunc(pad.horinicio) -- LIMITA A PEGAR DATA DENTRO DO RANGE DO MESMO DIA
          and trunc(pad.horinicio)               >= (trunc(pdatabase) + 7)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.INDATIVO                       = 'Y'
        --and pad.HORINICIO                      > sysdate --removido por causa da parametrizacao VERIFICAR POR CAUSA DA REGRA DOS 7 DIAS
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
          and pga.codperito                      = pperito--v_perito_agendamento.codperito
          and pga.codperitoperfil                = pp.codperitoperfil
          and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
          and pen.codespecialidadenatureza       = pespecialidadenatureza
          and pp.codraj                          = praj
          and pcdp                               is null
         --order by pad.horinicio asc;
          union
        select pad.codperitoagendadetalhe
        ,      pad.horinicio
        ,      pad.horfim
        from  peritoagendadetalhe         pad
        ,     peritoagenda                pa
        ,     peritogeracaoagenda         pga
        ,     peritoperfil                pp
        ,     peritoespecialidadenatureza pen
        ,     perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.qtdpericiasrestantes            >= 1
          and pa.datatendimento                  = trunc(pad.horinicio) -- LIMITA A PEGAR DATA DENTRO DO RANGE DO MESMO DIA
          and trunc(pad.horinicio)               >= (trunc(pdatabase) + 7)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.INDATIVO                       = 'Y'
        --and pad.HORINICIO                      > sysdate --removido por causa da parametrizacao VERIFICAR POR CAUSA DA REGRA DOS 7 DIAS
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
          and pga.codperito                      = pperito--v_perito_agendamento.codperito
          and pga.codperitoperfil                = pp.codperitoperfil
          and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
          and pen.codespecialidadenatureza       = pespecialidadenatureza
          and pp.codcpd                          = pcdp
          and pcdp                               is not null      
          order by 2 asc;
      vdata_agendamento_reu c_data_agendamento_reu%rowtype;
    --
    cursor c_nome_reu (poficio number)is
    select upper(trim(op.nome)) nome
      from oficiopartes op
     where op.id_oficio = poficio
       and op.polo      = 'PA';
    --
    cursor c_periciandos_reu(poficio   in number
      						          ,pnome_reu in varchar2) is 
      select op.codpericiando
      ,      op.nomepericiando
      ,      op.situacaopericiando
        from oficiopericiando op 
       where op.id_oficio             = poficio
         and upper(trim(op.nomepericiando)) = upper(trim(pnome_reu));
         --and upper(trim(op.nomepericiando)) like ('%'||pnome_reu||'%');
    vpericiandos_reu c_periciandos_reu%rowtype;
    --
    cursor c_seq_prontuario_pericial_oficio(pprontuariopericialoficio in number) is
      select (nvl(max(pa.seqagendamento),0)+1)
      from periciaagendamento pa
      where pa.codprontuariopericialoficio = pprontuariopericialoficio;
    vseq_prontuario_pericial_oficio number;
    --
    cursor cperitoagenda (pperitoagendadetalhe in number) is 
    select pa.codperitoagenda,
           pa.qtdpericiasrestantes,
           pa.qtdavaliacoesrestantes
      from peritoagendadetalhe pad,
           peritoagenda pa
     where pad.codperitoagendadetalhe = pperitoagendadetalhe;
    vperitoagenda      cperitoagenda%rowtype;
    vperitoagenda_nova cperitoagenda%rowtype; 
    --
    vreupreso 					          varchar2(1);
    vdata_agendamento_prontuario  date;
    vid_pericia_agendamento 	    number;
    vdata_operacao		  		      date;
    vraj						              number;
    vmesma_especialidade_natureza varchar2(1) := 'N';
    --
    cursor c_perito_agenda_agendamento(pperito_agenda_detalhe in number) is 
      select pad.codperitoagenda
      from peritoagendadetalhe pad
      where pad.codperitoagendadetalhe = pperito_agenda_detalhe;
    vcodperitoagenda number;
    --
    cursor c_verifica_agenda_completa(pcodperitoagenda in number) is 
      select 1
      from peritoagendadetalhe pad
      where pad.codperitoagenda = pcodperitoagenda
        and pad.indreservado    = 'N';
    vverifica number;
    --
    cursor c_data_agenda_completa(pcodperitoagenda in number) is 
      select trunc(pad.horinicio)
      from peritoagendadetalhe pad
      where pad.codperitoagenda = pcodperitoagenda;
    vdata date;
    --
    cursor c_define_rotina_portaria(pprontuario_pericial_oficio in number) is 
      select o.localpericia
      from prontuariopericialoficio ppo
      ,    oficio                   o 
      where ppo.codprontuariopericialoficio = pprontuario_pericial_oficio
        and ppo.id_oficio                   = o.id_oficio;
    vlocal_pericia number;
    -- 
    cursor c_perito_agendamento_diretoria(pespecialidade in number      
							             ,pnatureza      in number      
      						             ,praj 	         in number
                                         ,pcdp	         in number default null
                                         ,pcodperito     in number) is  
	  select pt.codperito
	  ,	   	 p.nompessoa
	  ,	   	 en.codespecialidadenatureza
      ,      case 
               when pt.indefetivo = 'Y' or pt.indcredenciado = 'Y' then 'Y'
               else 'N' 
             end efetivocadastrado
	  from perito 			           pt
	  ,	   pessoaimesc 		 		   pi
	  ,	   pessoa		 		 	   p
	  ,    peritoespecialidade 		   pe
	  ,    peritoespecialidadenatureza pen
	  ,    especialidade			   e
	  ,    natureza				       n
	  ,	   especialidadenatureza       en
	  ,	   peritoperfil				   pp
      ,    peritogeracaoagenda         pga
      ,    peritoagenda                pa
      ,    peritoagendadetalhe         pad
	  where pt.codpessoaimesc                  = pi.codpessoaimesc
        and pt.indativo                          = 'Y'
        and pt.codperito <> pcodperito
	    and pi.situacaopessoaimesc             = 'Y'
	    and p.codpessoa      	               = pi.codpessoa
	    and pe.codperito		               = pt.codperito
	    and pe.indativo		                   = 'Y'
	    and pe.codperitoespecialidade          = pen.codperitoespecialidade
	    and e.codespecialidade 		           = pe.codespecialidade
	    and en.codespecialidadenatureza        = pen.codespecialidadenatureza
	    and en.indativo				           = 'Y'
	    and en.codnatureza			           = n.codnatureza
	    and n.codnatureza				       = pnatureza
	    and e.codespecialidade		           = pespecialidade
        and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
	    and pp.codperito  				       = pt.codperito
        and pga.codperitoperfil                = pp.codperitoperfil
        and pga.codperito                      = pp.codperito
        and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
        and pa.codperitoagenda                 = pad.codperitoagenda
        and pa.datatendimento                  = trunc(pad.horinicio)
        and pad.indreservado                   = 'N'
        and pad.indencaixe                     = 'N'
        and pad.indativo                       = 'Y'
        --and pad.horinicio                      > sysdate !!!!  
        and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
	    and ((pp.codraj	= praj  and  praj is not null)   or  (praj is null ))
        and  pcdp                               is null
        union
 
          select pt.codperito
	  ,	   	 p.nompessoa
	  ,	   	 en.codespecialidadenatureza
      ,      case 
               when pt.indefetivo = 'Y' or pt.indcredenciado = 'Y' then 'Y'
               else 'N' 
             end efetivocadastrado
	  from perito 			               pt
	  ,	   pessoaimesc 		 		         pi
	  ,	   pessoa		 		 	             p
	  ,    peritoespecialidade 		     pe
	  ,    peritoespecialidadenatureza pen
	  ,    especialidade			         e
	  ,    natureza				             n
	  ,	   especialidadenatureza       en
	  ,	   peritoperfil				         pp
      ,    peritogeracaoagenda         pga
      ,    peritoagenda                pa
      ,    peritoagendadetalhe         pad
	  where pt.codpessoaimesc                  = pi.codpessoaimesc
        and pt.indativo                        = 'Y'
        and pt.codperito <> pcodperito
	    and pi.situacaopessoaimesc             = 'Y'
	    and p.codpessoa      	                 = pi.codpessoa
	    and pe.codperito		                   = pt.codperito
	    and pe.indativo		                     = 'Y'
	    and pe.codperitoespecialidade          = pen.codperitoespecialidade
	    and e.codespecialidade 		             = pe.codespecialidade
	    and en.codespecialidadenatureza        = pen.codespecialidadenatureza
	    and en.indativo				                 = 'Y'
	    and en.codnatureza			               = n.codnatureza
	    and n.codnatureza				               = pnatureza
	    and e.codespecialidade		             = pespecialidade
      and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
	    and pp.codperito  				             = pt.codperito
      and pga.codperitoperfil                = pp.codperitoperfil
      and pga.codperito                      = pp.codperito
      and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
      and pa.codperitoagenda                 = pad.codperitoagenda
      and pa.datatendimento                  = trunc(pad.horinicio)
      and pad.indreservado                   = 'N'
      and pad.indencaixe                     = 'N'
      and pad.indativo                       = 'Y'
        --and pad.horinicio                      > sysdate !!!!  
      and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
	    and pp.codcpd                          = pcdp
        and pcdp                               is not null     
        order by 4  desc; --desc, pt.indcredenciado desc, pt.indcadastrado desc;
	v_perito_agendamento_diretoria c_perito_agendamento_diretoria%rowtype;
    --
    
    -- 13/09/2023 não pode subir para produção com esse parametro pidagendamentopericia 
    procedure prc_agendamento_protocolo(pprotocolo                in number default null
    								   ,ptipo_agendamento         in varchar2 default null
                                       ,pprontuariopericialoficio in number default null -- A: Avaliação P: Pericia
                                       ,ptriagem                  in varchar2 default null  --Y triagem(ccfal,psicol)
                                       ,pidagendamentopericia     out number) is  
      --
      cursor c_protocolo_agendamento is
        select p.id_protocolo
        ,	   p.id_oficio
        ,      p.numero_processo
        from protocolo p
        where p.status = 'AGUARDANDO AGENDAMENTO'
         and ((p.id_protocolo = pprotocolo and pprotocolo is not null)
               or (pprotocolo is null))
       --  and p.id_protocolo not in (202300004669,202300004679)
       order by p.data_protocolo asc;
      --
      vqt_periciando        number(2);
      vpsiquiatria          varchar2(1);
      vqtdpericiando        number := 0;
      vraj                  number;
      vidpericiaagendamento number;
      vpsicologia    varchar2(10);
      vvalida        varchar2(10);
      vqtpericiando  number;
      mensagem_erro   varchar2(400);
      --
      verro varchar2(1);
      --
      cursor c_descricao_especialidade is
		select e.desespecialidade
		from especialidade e 
		where e.codespecialidade = vdados_oficio.especialidade;
      vespecialidade varchar2(60);
 
      cursor c_existe_periciando_indireto(pid_oficio in number )is
       select nvl((select 'S'
               from    oficio o,
                       oficiopericiando op
              where    o.id_oficio = op.id_oficio
              and      o.id_oficio = pid_oficio
              and      op.indireto = 'Y'
              and      rownum = 1  ),'N') from dual;   
      vexistpericiandoindireto varchar2(2);           
      --
    begin
      

      --
      for r_protocolo_agendamento in c_protocolo_agendamento
      loop
	    --
        open c_dados_oficio(r_protocolo_agendamento.id_oficio);
        fetch c_dados_oficio into vdados_oficio;
        close c_dados_oficio; 
        --
        vqt_periciando := vdados_oficio.qtdpericiando;
        --
        vpsiquiatria := 'N';
		--
		open c_descricao_especialidade;
		fetch c_descricao_especialidade into vespecialidade;
		close c_descricao_especialidade;
		--
        if upper(vespecialidade) = upper('psicologia') then 
		  --
		  vpsiquiatria := 'S';
          --
          if nvl(ptipo_agendamento,'P') = 'P' then
            --
            vqtdpericiando := laudo_pkg_agendamento.fnc_retorna_qtd_reu(poficio => r_protocolo_agendamento.id_oficio);
            --
          end if;
          --
		end if;
		--
        open c_existe_periciando_indireto(pid_oficio =>r_protocolo_agendamento.id_oficio );
    	fetch c_existe_periciando_indireto into vexistpericiandoindireto;
    	close c_existe_periciando_indireto;
        --
        if (vdados_oficio.localpericia = 2 or (ptriagem is not null and vexistpericiandoindireto = 'S' and ptriagem ='Y')) then 
          --
          vraj := 1;
          -- 
        else
          --
          vraj := '';
          --    
        end if;
        --
        if (nvl(ptipo_agendamento,'P') = 'A' and vpsiquiatria = 'S') or (nvl(ptipo_agendamento,'P') = 'A' and vqt_periciando > 1) then
          --
          vqt_periciando := 1;
          --
        end if;
        --
   
        if nvl(ptipo_agendamento,'P') = 'P' and  vpsiquiatria = 'S' then
          --
           insert into LOG_AGENDAMENTO(  FLUXO,DATA)
           values ('prc_valida_agendamento_entrou_s',sysdate);

          laudo_pkg_agendamento.prc_valida_psicologia(pespecialidade        => vdados_oficio.especialidade,
                                                      pnatureza             => vdados_oficio.natureza,
                                                      poficio               => r_protocolo_agendamento.id_oficio,
                                                      ptipo_agendamento     => nvl(ptipo_agendamento,'P'),
                                                      pqtdpericiando        => (vqt_periciando - vqtdpericiando),
                                                      pprotocolo            => r_protocolo_agendamento.id_protocolo,
                                                      pcdp                  => vdados_oficio.cdp,
                                                      perro                 => verro,
                                                      ppsicologia           => vpsicologia,
                                                      pvalida               => vvalida,
                                                      pidpericiaagendamento => vidpericiaagendamento,
                                                      pqtpericiando         => vqtpericiando);
        
          if vvalida = 'S' and  verro <> 'S' then
            --
            insert into LOG_AGENDAMENTO( FLUXO,DATA)
            values ('prc_valida_agendamento_entrou_s',sysdate);

            laudo_pkg_agendamento.prc_valida_agendamento(pid_oficio                => r_protocolo_agendamento.id_oficio
                                                        ,pespecialidade  	       => vdados_oficio.especialidade
                                                        ,pnatureza       	       => vdados_oficio.natureza
                                                        ,praj            	       => nvl(vraj,vdados_oficio.raj)
                                                        ,pqtd_periciando 	       => vqtpericiando
                                                        ,psituacao_periciando      => vdados_oficio.situacaopericiando
                                                        ,ptipo_agendamento         => nvl(ptipo_agendamento, 'P')
                                                        ,ppsiquiatria              => vpsicologia
                                                        ,pprontuariopericialoficio => pprontuariopericialoficio
                                                        ,pcdp                      => vdados_oficio.cdp
                                                        --retorno
                                                        ,perro          		   => verro
                                                        ,pexiste_mesma_especinat   => vmesma_especialidade_natureza
                                                        ,pidpericiaagendamento     => vidpericiaagendamento);
            --
            
            if nvl(verro, 'N') = 'N' then --if verro != 'S' then 
              --

              if vqtpericiando > 1 then
                -- 
                   insert into LOG_AGENDAMENTO(  FLUXO,DATA)
                   values     ('prc_agendar_sequencia_entrou_s',sysdate);
                laudo_pkg_agendamento.prc_agendar_sequencia(poficio               => r_protocolo_agendamento.id_oficio
                                                           ,pprotocolo            => r_protocolo_agendamento.id_protocolo--r_protocolo_agendamento.id_oficio
                                                           ,pqtd_periciando       => vqtpericiando
                                                           ,ptipo_agendamento     => nvl(ptipo_agendamento, 'P')
                                                           ,ppsiquiatria          => vpsicologia
                                                           ,pcdp                  => vdados_oficio.cdp
                                                           ,pidpericiaagendamento => vidpericiaagendamento);
                --
                 pidagendamentopericia := vidpericiaagendamento;
                --
              else
                --
                if vmesma_especialidade_natureza != 'S' then
                  --
                    insert into LOG_AGENDAMENTO(  FLUXO,DATA)
                   values       ('prc_agendar_entrou_s',sysdate);

                  laudo_pkg_agendamento.prc_agendar(poficio    		          => r_protocolo_agendamento.id_oficio
                                                   ,pprotocolo 		          => r_protocolo_agendamento.id_protocolo
                                                   ,ptipo_agendamento         => nvl(ptipo_agendamento, 'P')
                                                   ,ppsiquiatria              => vpsicologia
                                                   ,pprontuariopericialoficio => pprontuariopericialoficio
                                                   ,pcdp                      => vdados_oficio.cdp
                                                   ,pidpericiaagendamento     => vidpericiaagendamento);
                  --
                   pidagendamentopericia := vidpericiaagendamento;
                  --
                end if;
                --
              end if;
              --
            end if;
            --  
          end if;
          --
        else
          --

            insert into LOG_AGENDAMENTO(  FLUXO,DATA)
            values            ('prc_valida_agendamento_entrou_n',sysdate);
          
          laudo_pkg_agendamento.prc_valida_agendamento(pid_oficio                => r_protocolo_agendamento.id_oficio
                                                      ,pespecialidade  	         => vdados_oficio.especialidade
                                                      ,pnatureza       	         => vdados_oficio.natureza
                                                      ,praj            	         => nvl(vraj,vdados_oficio.raj)
                                                      ,pqtd_periciando 	         => (vqt_periciando - vqtdpericiando)
                                                      ,psituacao_periciando      => vdados_oficio.situacaopericiando
                                                      ,ptipo_agendamento         => nvl(ptipo_agendamento, 'P')
                                                      ,ppsiquiatria              => vpsiquiatria
                                                      ,pprontuariopericialoficio => pprontuariopericialoficio
                                                      ,pcdp                      => vdados_oficio.cdp
                                                      --retorno
                                                      ,perro          		     => verro
                                                      ,pexiste_mesma_especinat   => vmesma_especialidade_natureza
                                                      ,pidpericiaagendamento     => vidpericiaagendamento);
   
          --

          if nvl(verro, 'N') = 'N' then --if verro != 'S' then 
            --
            if vqt_periciando > 1 then
                              --
                   insert into LOG_AGENDAMENTO(  FLUXO, DATA)
                   values      ('prc_agendar_sequencia_entrou_N',sysdate);
                                 
              laudo_pkg_agendamento.prc_agendar_sequencia(poficio              => r_protocolo_agendamento.id_oficio
                                                        ,pprotocolo            => r_protocolo_agendamento.id_protocolo--r_protocolo_agendamento.id_oficio
                                                        ,pqtd_periciando       => (vqt_periciando - vqtdpericiando)
                                                        ,ptipo_agendamento     => nvl(ptipo_agendamento, 'P')
                                                        ,ppsiquiatria          => vpsiquiatria
                                                        ,pcdp                  => vdados_oficio.cdp
                                                        ,pidpericiaagendamento => vidpericiaagendamento);
              --
               pidagendamentopericia := vidpericiaagendamento;
              --
            else
              --
              if vmesma_especialidade_natureza != 'S' then
                --
                   insert into LOG_AGENDAMENTO(FLUXO,DATA)
                   values      ('prc_agendar_entrou_N',sysdate);
                                    

                laudo_pkg_agendamento.prc_agendar(poficio    		        => r_protocolo_agendamento.id_oficio
                                                 ,pprotocolo 		        => r_protocolo_agendamento.id_protocolo
                                                 ,ptipo_agendamento         => nvl(ptipo_agendamento, 'P')
                                                 ,ppsiquiatria              => vpsiquiatria
                                                 ,pprontuariopericialoficio => pprontuariopericialoficio
                                                 ,pcdp                      => vdados_oficio.cdp
                                                 ,pidpericiaagendamento     => vidpericiaagendamento);
                --
                 pidagendamentopericia := vidpericiaagendamento;
              end if;
              --
            end if; 
            --
          end if;
          --
        end if;
        -- 
 	  end loop;
      --
          commit;
       exception
      when others then
      mensagem_erro := SQLERRM;
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 vdados_oficio.especialidade,
                                 vdados_oficio.natureza,
                                 '',
                                 ptipo_agendamento,
                                 '',
                                 '',
                                 '',
                                 mensagem_erro,
                                 '',
                                 '', 
                                 vidpericiaagendamento,
                                 '', 
                                 vraj, 
                                 vreupreso,
                                 vpsiquiatria, 
                                 pprontuariopericialoficio,
                                vmesma_especialidade_natureza,
                                'prc_agendamento_protocolo',
                                sysdate); 
                                commit;
                            
    end prc_agendamento_protocolo;
    --
    procedure prc_valida_agendamento(pid_oficio	               in number
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
                                    ,pidpericiaagendamento     out number) is
      --
      erro_tratado exception;
      vqtd_periciando number := pqtd_periciando;
      --

      cursor c_verifica_perfil_agenda is
        select 1 
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pp.codraj                          = praj
          and pcdp                               is null
          union
         select 1 
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pp.codcpd                          = pcdp
          and pcdp                                is not null;
      --
      cursor c_verifica_agenda_periciando(pqtd_periciando in number) is 
        select pad.codperitoagendadetalhe codigo_agenda
        ,      trunc(pad.horinicio)       data_agenda
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    peritogeracaoagenda         pga
        ,    peritoagenda                pa
        ,    peritoagendadetalhe         pad
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pga.codperitoperfil                = pp.codperitoperfil
          and pga.codperito                      = pp.codperito
          and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.datatendimento                  = trunc(pad.horinicio)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.indativo                       = 'Y'
          --and pad.horinicio                      > sysdate -- removido devido a parametrizacao
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pp.codraj                          = praj
          and pcdp                               is null
          and ((pa.qtdpericiasrestantes >= pqtd_periciando and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes >= pqtd_periciando and ptipo_agendamento = 'A'))
        --and pqtd_periciando                    = 1
          and not exists (select 1
                          from rajdianaotrabalhado rnt
                          where rnt.codraj              = pp.codraj
                            and rnt.datdianaotrabalhado = trunc(pad.horinicio))
          and pad.codperitoagendadatastrancadas is null
          union 
        select pad.codperitoagendadetalhe codigo_agenda
        ,      trunc(pad.horinicio)       data_agenda
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    peritogeracaoagenda         pga
        ,    peritoagenda                pa
        ,    peritoagendadetalhe         pad
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pga.codperitoperfil                = pp.codperitoperfil
          and pga.codperito                      = pp.codperito
          and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.datatendimento                  = trunc(pad.horinicio)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.indativo                       = 'Y'
          --and pad.horinicio                      > sysdate -- removido devido a parametrizacao
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pp.codcpd                          = pcdp
          and pcdp                                is not null
          and ((pa.qtdpericiasrestantes >= pqtd_periciando and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes >= pqtd_periciando and ptipo_agendamento = 'A'))
        --and pqtd_periciando                    = 1
          and not exists (select 1
                          from rajdianaotrabalhado rnt
                          where rnt.codraj              = pp.codraj
                            and rnt.datdianaotrabalhado = trunc(pad.horinicio))
          and pad.codperitoagendadatastrancadas is null;
          
 
       vverifica_agenda_periciando c_verifica_agenda_periciando%rowtype;
   
    --
    cursor c_define_prontuario is
    select o.numeroprocesso
        ,  ppo.idprontuariopericial
        ,  ppo.codprontuariopericialoficio
        ,  ppo.idprotocolo
    from prontuariopericialoficio ppo,
         oficio o
    where ppo.id_oficio = o.id_oficio 
      and ppo.codprontuariopericialoficio = pprontuariopericialoficio;
    --
    cursor c_prontuario is
		select o.numeroprocesso
        ,  ppo.idprontuariopericial
        ,  ppo.codprontuariopericialoficio
        ,  ppo.idprotocolo
	  	from prontuariopericialoficio ppo,
           oficio o
		 where ppo.id_oficio = o.id_oficio
       and ppo.id_oficio = pid_oficio;
     vprontuario c_prontuario%rowtype;
     --
      cursor c_mesma_especialidade_natureza(pprontuario in number) is
		select 1
		from prontuariopericialoficio ppo
		where ppo.idprontuariopericial = pprontuario
      and exists (select 1
                  from periciaagendamento pa
                  ,    peritoagendadetalhe pad
                  ,    especialidadenatureza en
              where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
                and pa.codperitoagendadetalhe      = pad.codperitoagendadetalhe
                and pa.indativo                    = 'Y'
                --and pad.horinicio                  > sysdate !!!!
                and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                   and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                    and pad.HORINICIO > sysdate))
                and pa.codespecialidadenatureza    = en.codespecialidadenatureza
                and en.codnatureza                 = pnatureza
                and en.codespecialidade            = pespecialidade
                and pa.tipo                        = ptipo_agendamento);
      --
     cursor c_mesma_especialidade_natureza_processo(pprontuario in number, pprocesso in varchar2) is 
       select 1
        from prontuariopericialoficio ppo,
             oficio o
        where ppo.idprontuariopericial = pprontuario
          and ppo.id_oficio            = o.id_oficio
          and o.numeroprocesso         <> pprocesso
          and exists (select 1
                      from periciaagendamento pa
                      ,    peritoagendadetalhe pad
                      ,    especialidadenatureza en
                      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
                        and pa.codperitoagendadetalhe      = pad.codperitoagendadetalhe
                        and pa.indativo                    = 'Y'
                        and pad.horinicio                  > sysdate 
                        /*and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                           and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                        or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                            and pad.HORINICIO > sysdate))*/
                        and pa.codespecialidadenatureza    = en.codespecialidadenatureza
                        and en.codnatureza                 = pnatureza
                        and en.codespecialidade            = pespecialidade
                        and pa.tipo                        = ptipo_agendamento);      
      
      cursor c_especialidade_natureza is
        select en.codespecialidadenatureza
        from especialidadenatureza en
        where en.codespecialidade = pespecialidade
          and en.codnatureza 	  = pnatureza;
      vcod_especialidade_natureza number;
      --
      cursor c_agendamento_mesma_especialidade_natureza(pprontuario 			    in number
        											                         ,pcod_especialidade_natureza in number) is
         select min(pa.codperitoagendadetalhe) codperitoagendadetalhe
          ,     pa.codperito
          ,     pa.indefetivocadastrado
           from periciaagendamento pa,
                prontuariopericialoficio ppo,
                peritoagendadetalhe pad 
          where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
            and pa.codespecialidadenatureza    = pcod_especialidade_natureza
            and ppo.idprontuariopericial       = pprontuario
            and pad.codperitoagendadetalhe     = pa.codperitoagendadetalhe
            --and pad.horinicio > sysdate !!!!
            and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          group by pa.codperito,
                   pa.indefetivocadastrado;
      vdados_agendamento_mesma_especinat c_agendamento_mesma_especialidade_natureza%rowtype;
      --
      cursor c_verifica_agenda_reu(pdata_base_periciando in date) is 
        select 1 
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    peritogeracaoagenda         pga
        ,    peritoagenda                pa
        ,    peritoagendadetalhe         pad
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pga.codperitoperfil                = pp.codperitoperfil
          and pga.codperito                      = pp.codperito
          and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.datatendimento                  = trunc(pad.horinicio)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.indativo                       = 'Y'
          and pp.codraj                          = praj
          and pcdp                             is null
          and trunc(pad.horinicio)				      >= trunc(pdata_base_periciando) + 7
          -- PARAMETRIZACAO???
          and ((pa.qtdpericiasrestantes > 0 and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes > 0 and ptipo_agendamento = 'A'))
        --and pqtd_periciando                    = 1
          and not exists (select 1
                          from rajdianaotrabalhado rnt
                          where rnt.codraj              = pp.codraj
                            and rnt.datdianaotrabalhado = trunc(pad.horinicio))
          and pad.codperitoagendadatastrancadas is null
             union
 
            select 1 
            from especialidadenatureza       en
            ,    peritoespecialidadenatureza pen
            ,    peritoperfil                pp
            ,    peritogeracaoagenda         pga
            ,    peritoagenda                pa
            ,    peritoagendadetalhe         pad
            ,    perito                      pt
            where pp.codperito                       = pt.codperito
              and pt.indativo                        = 'Y'  
              and en.codespecialidade                = pespecialidade
              and en.codnatureza                     = pnatureza 
              and en.codespecialidadenatureza        = pen.codespecialidadenatureza
              and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
              and pga.codperitoperfil                = pp.codperitoperfil
              and pga.codperito                      = pp.codperito
              and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
              and pa.codperitoagenda                 = pad.codperitoagenda
              and pa.datatendimento                  = trunc(pad.horinicio)
              and pad.indreservado                   = 'N'
              and pad.indencaixe                     = 'N'
              and pad.indativo                       = 'Y'
              and pp.codcpd                          = pcdp
              and pcdp                                is not null
              and trunc(pad.horinicio)				      >= trunc(pdata_base_periciando) + 7
              -- PARAMETRIZACAO???
              and ((pa.qtdpericiasrestantes > 0 and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes > 0 and ptipo_agendamento = 'A'))
            --and pqtd_periciando                    = 1
              and not exists (select 1
                              from rajdianaotrabalhado rnt
                              where rnt.codraj              = pp.codraj
                                and rnt.datdianaotrabalhado = trunc(pad.horinicio))
              and pad.codperitoagendadatastrancadas is null;
      
      --
      vverifica               number;
      vverifica2              number;
      verro                   varchar2(1) := 'N';
      vretorno                varchar2(200);
      vverifica_codigo_agenda number;
      vverifica_data_agenda   date;
      vencontrou_sequencia    varchar2(1) := 'N';
      vdata_base_sequencia    date;
      vqtd_reu                number := 0;
      mensagem_erro           varchar(400);      --
      cursor c_protocolo_oficio is 
        select p.id_protocolo
        from protocolo p 
    	where p.id_oficio = pid_oficio;
      vprotocolo protocolo.id_protocolo%type;
      --
      cursor c_prontuario_pericial (poficio    in number
        						   ,pprotocolo in number) is
        select ppo.codprontuariopericialoficio
          from prontuariopericialoficio ppo
         where ppo.idprotocolo = pprotocolo
           and ppo.id_oficio   = poficio
           and ppsiquiatria = 'N'
        union
        select ppo.codprontuariopericialoficio
        from prontuariopericialoficio ppo
        where ppo.idprotocolo = pprotocolo
          and ppo.id_oficio   = poficio
          and ppsiquiatria    = 'S'
          and codprontuariopericialoficio not in nvl(laudo_pkg_agendamento.fnc_retorna_protuario_oficio_reu(poficio => poficio, pprotocolo => pprotocolo), 0);
      vprontuariopericial number;
      --
    begin 
      --raise_application_error(-20001,'pid_oficio: '||pid_oficio||' pespecialidade: '||pespecialidade||' pnatureza: '||pnatureza||' praj: '||praj||' ppsiquiatria: '||ppsiquiatria||' ptipo_agendamento: '||ptipo_agendamento);
      --
      perro := 'N';
      
      open c_verifica_perfil_agenda;
      fetch c_verifica_perfil_agenda into vverifica;
 
      if c_verifica_perfil_agenda%notfound then
        --
        verro    := 'S';
        vretorno := 'Agendamento não realizado, perfil de agenda não encontrado!';
        raise erro_tratado;
        --
      end if;
      close c_verifica_perfil_agenda;

    
    if (ptipo_agendamento = 'A' and  ppsiquiatria = 'S') or (ptipo_agendamento = 'A' and  pqtd_periciando > 1) then
      
       vqtd_periciando := 1;
   
    end if;
     
      --
      if ppsiquiatria = 'S' and ptipo_agendamento = 'P' then
      --
      pexiste_mesma_especinat := 'N';
      --
      for r_reu in c_nome_reu(pid_oficio)
      loop
        --
        open c_periciandos_reu(poficio   => pid_oficio
                              ,pnome_reu => r_reu.nome);
        fetch c_periciandos_reu into vpericiandos_reu;
        if c_periciandos_reu%notfound then
              close c_periciandos_reu;
        --
        vqtd_reu := vqtd_reu + 1;
        verro    := 'S';
        vretorno := 'Agendamento de psiquiatria não realizado, réu não encontrado!';
        raise erro_tratado;
        --
        end if;
            close c_periciandos_reu;
        --
        end loop;
          --
      if pqtd_periciando = 1 then
        --
        open c_verifica_agenda_periciando(pqtd_periciando);
        fetch c_verifica_agenda_periciando into vverifica_agenda_periciando;
        if c_verifica_agenda_periciando%notfound then
          --
        verro    := 'S';
        vretorno := 'Agendamento de psiquiatria não realizado, agenda não disponível!';
        raise erro_tratado;
        --
        end if;
        close c_verifica_agenda_periciando;
        --
        open c_perito_agendamento(pespecialidade, pnatureza, praj,pcdp);
        fetch c_perito_agendamento into v_perito_agendamento;
        close c_perito_agendamento;
        --  
        open c_especialidade_natureza;
        fetch c_especialidade_natureza into vcod_especialidade_natureza;
        close c_especialidade_natureza;
        --
        open c_data_agendamento(pespecialidadenatureza => vcod_especialidade_natureza
                               ,praj                   => praj
                               ,pcdp                   => pcdp );
        fetch c_data_agendamento into vdata_agendamento;
        close c_data_agendamento;
        --   
        open c_verifica_agenda_reu(pdata_base_periciando => vdata_agendamento.horinicio);
        fetch c_verifica_agenda_reu into vverifica;
        if c_verifica_agenda_reu%notfound then
        --
        verro    := 'S';
        vretorno := 'Agendamento de psiquiatria não realizado, agenda não disponível para o réu!';
        raise erro_tratado;
        --
        end if;
        close c_verifica_agenda_reu;
        --
        else
        --
        for r_verifica_agenda_periciando in c_verifica_agenda_periciando(pqtd_periciando)
        loop
        --
        if (nvl(vverifica_codigo_agenda,0) = r_verifica_agenda_periciando.codigo_agenda - 1) and (vverifica_data_agenda = r_verifica_agenda_periciando.data_agenda) then
          --
          vencontrou_sequencia := 'S';
          exit;
          --
        end if;
        --
        vverifica_codigo_agenda := r_verifica_agenda_periciando.codigo_agenda;
        vverifica_data_agenda   := r_verifica_agenda_periciando.data_agenda;
        --
        end loop;
        --
        if vencontrou_sequencia != 'S' then
        --
        verro    := 'S';
        vretorno := 'Agendamento psiquiatria não realizado, agenda não disponível!';
        raise erro_tratado;
        --
        end if;
        --
        open c_perito_agendamento(pespecialidade, pnatureza, praj,pcdp);
        fetch c_perito_agendamento into v_perito_agendamento;
        close c_perito_agendamento;
        --  
        for r_valida_sequencia in (select pad.codperitoagendadetalhe
                     ,      pad.horinicio
                     ,	    pad.horfim
                     from peritoagenda                pa
                     ,    peritoagendadetalhe         pad
                     ,    peritogeracaoagenda         pga
                     ,    peritoperfil                pp
                     ,    peritoespecialidadenatureza pen
                     ,    perito                      pt
                     where pp.codperito                       = pt.codperito
                       and pt.indativo                        = 'Y' 
                       and pa.codperitoagenda                 = pad.codperitoagenda
                       and pa.qtdpericiasrestantes            >= pqtd_periciando
                       and pa.datatendimento                  = trunc(pad.horinicio)
                       and pad.indreservado 	                = 'N'
                       and pad.indencaixe	 	                  = 'N'
                       and pad.INDATIVO 		                  = 'Y'
                       --and pad.HORINICIO					            > sysdate !!!!
                       and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                           and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                        or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                            and pad.HORINICIO > sysdate))
                       and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
                       and pga.codperito                      = v_perito_agendamento.codperito
                       and pga.codperitoperfil                = pp.codperitoperfil
                       and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
                       and pen.codespecialidadenatureza       =v_perito_agendamento.codespecialidadenatureza
                       --and ((pa.qtdpericiasrestantes > 0 and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes > 0 and ptipo_agendamento = 'A'))
                     order by pad.horinicio asc
                     fetch first pqtd_periciando rows only)
            loop
        --
        vdata_base_sequencia := r_valida_sequencia.horinicio;
          --
        end loop;
        -- 
        open c_verifica_agenda_reu(pdata_base_periciando => vdata_base_sequencia);
        fetch c_verifica_agenda_reu into vverifica;
        if c_verifica_agenda_reu%notfound then
        --
        verro    := 'S';
        vretorno := 'Agendamento de psiquiatria não realizado, agenda não disponível para o réu!';
        raise erro_tratado;
        --
        end if;
        close c_verifica_agenda_reu;
        --
      end if;
      --
      else 
      --
      if vqtd_periciando = 1 then
        

       if (ptipo_agendamento = 'A' and  ppsiquiatria = 'S') or (ptipo_agendamento = 'A' and  pqtd_periciando > 1) then
       
          open c_define_prontuario;
          fetch c_define_prontuario into vprontuario;
          close c_define_prontuario;
       
       else 
          --
          open c_prontuario;
          fetch c_prontuario into vprontuario;
          close c_prontuario;
          --
       end if;
        --
        pexiste_mesma_especinat := 'N';
        --
        open c_mesma_especialidade_natureza( pprontuario => vprontuario.idprontuariopericial);
        fetch c_mesma_especialidade_natureza into vverifica;
        
            if c_mesma_especialidade_natureza%found then
         --
           close c_mesma_especialidade_natureza;
           
            pexiste_mesma_especinat := 'S';
            
            laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => vprontuario.idprotocolo
  										 			                                 ,pstatus    => 'AGENDADO ANTERIORMENTE');
       -- 
       open c_mesma_especialidade_natureza_processo( pprontuario => vprontuario.idprontuariopericial,
                                                     pprocesso   => vprontuario.numeroprocesso);
        fetch c_mesma_especialidade_natureza_processo into vverifica2;
        
        if c_mesma_especialidade_natureza_processo%found then
        --
        open c_especialidade_natureza;
        fetch c_especialidade_natureza into vcod_especialidade_natureza;
        close c_especialidade_natureza;
        --
        open c_agendamento_mesma_especialidade_natureza(pprontuario 			      => vprontuario.idprontuariopericial
                                 ,pcod_especialidade_natureza => vcod_especialidade_natureza);
        fetch c_agendamento_mesma_especialidade_natureza into vdados_agendamento_mesma_especinat;
        close c_agendamento_mesma_especialidade_natureza;
              --
        --
        if psituacao_periciando = 2 then
          --
          vreupreso := 'S';
          --
        else
          --
          vreupreso := 'N';
          --
        end if;
        --
        open c_protocolo_oficio;
              fetch c_protocolo_oficio into vprotocolo;
              close c_protocolo_oficio;
              --
              open c_prontuario_pericial(pid_oficio, vprotocolo);
              fetch c_prontuario_pericial into vprontuariopericial;
            close c_prontuario_pericial;
              --
        open c_perito_agendamento(pespecialidade, pnatureza, praj,pcdp);
        fetch c_perito_agendamento into v_perito_agendamento;
        close c_perito_agendamento;
        --
        open c_data_agendamento(pespecialidadenatureza => v_perito_agendamento.codespecialidadenatureza
                               ,praj                   => praj
                                ,pcdp                   => pcdp);
        fetch c_data_agendamento into vdata_agendamento;
        close c_data_agendamento;
        --
        vdata_agendamento_prontuario := trunc(vdata_agendamento.horinicio);
        --
        insert into periciaAgendamento
             (codperito
             ,horchegada
             ,codprontuariopericialOficio
             ,codperitoagendadetalhe
             ,codespecialidadenatureza
             ,indreupreso
             ,indativo
             ,codpessoaacompanhante
             ,numdocumentoacompanhante
             ,datoperacao
             ,codusuariooperacao
             ,indefetivocadastrado
             ,situacao
             ,tipo
             ,seqagendamento
             ,tipopericia
             ,peticionamento)
        values (vdados_agendamento_mesma_especinat.codperito
             ,null
             ,vprontuario.codprontuariopericialoficio
             ,vdados_agendamento_mesma_especinat.codperitoagendadetalhe
             ,vcod_especialidade_natureza
             ,vreupreso
             ,'Y' -- Agendamento sempre entra como ativo
             ,null
             ,null
             ,sysdate
             ,nvl(v('GLOBAL_ID_USUARIO'),1)
             ,vdados_agendamento_mesma_especinat.indefetivocadastrado
             ,'AGENDADA/AGUARDANDO'
             ,nvl(ptipo_agendamento,'P')
             ,0
             ,nvl(ptipo_agendamento,'P')
             ,'PENDENTE');
        --
        vid_pericia_agendamento := seq_periciaagendamento.currval;
              --
        insert into historico_pericia_agendamento
             (id_periciaagendamento
             ,codperito
             ,codprontuariopericialoficio
             ,codperitoagendadetalhe
             ,codespecialidadenatureza
             ,codusuariooperacao
             ,dataoperacao
             ,indefetivocadastrado
             ,indurgente
             ,indativo)
        values (vid_pericia_agendamento
             ,v_perito_agendamento.codperito
             ,vprontuariopericial
             ,vdata_agendamento.codperitoagendadetalhe
             ,v_perito_agendamento.codespecialidadenatureza
             ,nvl(v('GLOBAL_ID_USUARIO'),1) -- Integração
             ,vdata_operacao
             ,v_perito_agendamento.efetivocadastrado
             ,'N'
             ,'Y'); 
              --
              laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => vprotocolo
                                       ,pstatus    => 'AGENDADO');
              --
              update prontuariopericialoficio ppo
          set ppo.dataagendamento = vdata_agendamento_prontuario
          where ppo.id_oficio = pid_oficio;
              --
           pidpericiaagendamento := vid_pericia_agendamento ;
            
         end if; 
         
         close c_mesma_especialidade_natureza_processo;
          
        else
              -- 
        open c_verifica_agenda_periciando(vqtd_periciando);
        fetch c_verifica_agenda_periciando into vverifica_agenda_periciando;
        if c_verifica_agenda_periciando%notfound then
          --
   
          verro    := 'S';
          vretorno := 'Agendamento não realizado, agenda não disponível!';
          raise erro_tratado;
          --
        end if;
        close c_verifica_agenda_periciando;
        --
        end if;
        --
      else -- Mais de um periciando 1
        --
            --  raise_application_error(-20001, vverifica);
        for r_verifica_agenda_periciando in c_verifica_agenda_periciando(pqtd_periciando)
        loop
        --
        if (nvl(vverifica_codigo_agenda,0) = r_verifica_agenda_periciando.codigo_agenda - 1) and (vverifica_data_agenda = r_verifica_agenda_periciando.data_agenda) then
          --
          vencontrou_sequencia := 'S';
          exit;
          --
        end if;
        --
        vverifica_codigo_agenda := r_verifica_agenda_periciando.codigo_agenda;
        vverifica_data_agenda   := r_verifica_agenda_periciando.data_agenda;
        --
        end loop;
        --
        if vencontrou_sequencia != 'S' then
        --
        verro    := 'S';
        vretorno := 'Agendamento não realizado, agenda não disponível!';
        raise erro_tratado;
        --
        end if;
        --
      end if;
      --
      end if;
      --
      
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 pid_oficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 vprotocolo,
                                 perro ||' '|| vretorno,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 praj, 
                                 vreupreso,
                                ppsiquiatria, 
                                 vprontuariopericial,
                                pexiste_mesma_especinat,
                                'prc_valida_agendamento',
                                sysdate);

    commit;                           
    exception
      when erro_tratado then
      --insert na estrutura
      --raise_application_error(-20002,vretorno);
           perro := verro;
        insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 pid_oficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 vprotocolo,
                                 perro ||' '|| vretorno,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 praj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                pexiste_mesma_especinat,
                                'prc_valida_agendamento',
                                sysdate);
                                commit;
       when others then
         mensagem_erro := SQLERRM;
       -- raise_application_error(-20002,sqlerrm);
        insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 pid_oficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 vprotocolo,
                                 mensagem_erro,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 praj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                pexiste_mesma_especinat,
                                'prc_valida_agendamento',
                                sysdate);
                                commit;
                                
    end prc_valida_agendamento;
    --
    function fnc_qtd_periciando_oficio(poficio in number) return number is
      --
      vqt_periciando number(2);
      --
    begin
      --
      select count(*)
      into vqt_periciando
      from oficiopericiando op
      where op.id_oficio = poficio;
      --
      return vqt_periciando;
      --
    end fnc_qtd_periciando_oficio;
    --
    procedure prc_agendar(poficio    	            in number
	 		             ,pprotocolo                in number
	 		             ,ptipo_agendamento         in varchar2 default null 
	 		             ,ppsiquiatria              in varchar2
                         ,pprontuariopericialoficio in number default null
                         ,pcdp                      in number default null
                         ,pidpericiaagendamento     out number) is
      --
      cursor c_prontuario_pericial is
        select ppo.codprontuariopericialoficio
          from prontuariopericialoficio ppo
         where ppo.idprotocolo = pprotocolo
           and ppo.id_oficio   = poficio
           and ppsiquiatria = 'N'
        union
        select ppo.codprontuariopericialoficio
          from prontuariopericialoficio ppo
         where ppo.idprotocolo = pprotocolo
           and ppo.id_oficio   = poficio
           and ppsiquiatria    = 'S'
           and codprontuariopericialoficio not in nvl(laudo_pkg_agendamento.fnc_retorna_protuario_oficio_reu(poficio => poficio, pprotocolo => pprotocolo), 0);
      vprontuariopericial number;
      
      mensagem_erro VARCHAR2(1000);
      --
    begin
      --
      open c_dados_oficio(poficio);
      loop
      fetch c_dados_oficio into vdados_oficio;
      EXIT WHEN c_dados_oficio%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_dados_oficio',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_dados_oficio;
      --
      if vdados_oficio.localpericia = 2 then
        
         vraj := 1;
         
      else
        
        vraj := laudo_pkg_agendamento.fnc_define_raj(pdescentralizada => vdados_oficio.descentralizada
                                                    ,praj             => vdados_oficio.raj
                                                    ,pcomarca         => vdados_oficio.comarcaprocesso);
      end if;
      -- vdados_oficio.situacaopericiando == 3 ta certo ??
      --raise_application_error(-20002,vdados_oficio.situacaopericiando); 
     -- if vdados_oficio.situacaopericiando = 'Réu/Ré Preso(a)' then --- estava escrito
      if vdados_oficio.situacaopericiando = 2 then
        --
        vreupreso := 'S';
        --
      else
        --
        vreupreso := 'N';
        --
	  end if;
      --
      
 
      open c_perito_agendamento(vdados_oficio.especialidade, vdados_oficio.natureza,vraj,pcdp);
      loop
      fetch c_perito_agendamento into v_perito_agendamento;
       EXIT WHEN c_perito_agendamento%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_perito_agendamento',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_perito_agendamento;
      --
     
                                            
      open c_data_agendamento(pespecialidadenatureza => v_perito_agendamento.codespecialidadenatureza
                             ,pperito                => v_perito_agendamento.codperito  
                             ,praj                   => vraj
                             ,pcdp                   => pcdp);
      loop                       
      fetch c_data_agendamento into vdata_agendamento;
       EXIT WHEN c_data_agendamento%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_data_agendamento',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_data_agendamento;
      --
      vdata_agendamento_prontuario := trunc(vdata_agendamento.horinicio);
      --
	  update peritoagendadetalhe pad
	  set pad.indreservado = 'Y'
	  where pad.codperitoagendadetalhe = vdata_agendamento.codperitoagendadetalhe;
	  --
    --if ptipo_agendamento <> 'A'  then
      
        open c_prontuario_pericial;
        loop
        fetch c_prontuario_pericial into vprontuariopericial;
        EXIT WHEN c_prontuario_pericial%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_prontuario_pericial',sysdate,poficio,pprotocolo);
        END LOOP;
        close c_prontuario_pericial;
      --
    --end if;  
    
      
      vdata_operacao := sysdate;
      --
	  insert into periciaAgendamento
			 (codperito
			 ,horchegada
			 ,codprontuariopericialOficio
			 ,codperitoagendadetalhe
			 ,codespecialidadenatureza
			 ,indreupreso
			 ,indativo
			 ,codpessoaacompanhante
			 ,numdocumentoacompanhante
			 ,datoperacao
			 ,codusuariooperacao
			 ,indefetivocadastrado
			 ,situacao
			 ,tipo
			 ,seqagendamento
       ,tipopericia
       ,peticionamento)
	  values (v_perito_agendamento.codperito
			 ,null--vdata_agendamento.horinicio
			 ,nvl (vprontuariopericial, pprontuariopericialoficio)
			 ,vdata_agendamento.codperitoagendadetalhe
			 ,v_perito_agendamento.codespecialidadenatureza
			 ,vreupreso
			 ,'Y' -- Agendamento sempre entra como ativo
			 ,null
			 ,null
			 ,vdata_operacao
			 ,nvl(v('GLOBAL_ID_USUARIO'),1) 
			 ,v_perito_agendamento.efetivocadastrado
			 ,'AGENDADA/AGUARDANDO'
			 ,nvl(ptipo_agendamento,'P')
			 ,0
       ,nvl(ptipo_agendamento,'P')
       ,'PENDENTE');
      --
      
      vid_pericia_agendamento := seq_periciaagendamento.currval;
 
      pidpericiaagendamento := vid_pericia_agendamento;
	  --
     begin 
	  insert into historico_pericia_agendamento
        	 (id_periciaagendamento
        	 ,codperito
        	 ,codprontuariopericialoficio
        	 ,codperitoagendadetalhe
        	 ,codespecialidadenatureza
        	 ,codusuariooperacao
        	 ,dataoperacao
        	 ,indefetivocadastrado
        	 ,indurgente
        	 ,indativo)
	  values (vid_pericia_agendamento
	  		   ,v_perito_agendamento.codperito
	  		   ,vprontuariopericial
	  		   ,vdata_agendamento.codperitoagendadetalhe
	  		   ,v_perito_agendamento.codespecialidadenatureza
	  		   ,nvl(v('GLOBAL_ID_USUARIO'),1) -- Integração
	  		   ,vdata_operacao
	  		   ,v_perito_agendamento.efetivocadastrado
	  		   ,'N'
	  		   ,'Y'); 

      exception
      when others then
      mensagem_erro := SQLERRM;
     insert into LOG_AGENDAMENTO(  FLUXO,DATA)
     values ('historico_pericia_agendamento'||mensagem_erro,sysdate);
                  
      --
      end;
      
      open cperitoagenda(vdata_agendamento.codperitoagendadetalhe);
      loop
      fetch cperitoagenda into vperitoagenda;
        EXIT WHEN cperitoagenda%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('cperitoagenda',sysdate,poficio,pprotocolo);
        END LOOP;
      close cperitoagenda;
 
      if nvl(ptipo_agendamento, 'P') = 'P' then
      --   
        update peritoagenda pa
           set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes -1)
         where pa.codperitoagenda = vperitoagenda.codperitoagenda;
      --          
      elsif nvl(ptipo_agendamento, 'P') = 'A' then
      --    
        update peritoagenda pa
           set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes -1)
         where pa.codperitoagenda = vperitoagenda.codperitoagenda;
      --  
      end if;
      
      if ppsiquiatria = 'S' and ptipo_agendamento = 'P' then
      
         laudo_pkg_agendamento.prc_agendar_psicologia(poficio                => poficio
                                                     ,pprotocolo             => pprotocolo
                                                     ,pperito                => v_perito_agendamento.codperito
                                                     ,pdatabase              => vdata_agendamento_prontuario
                                                     ,pespecialidadenatureza => v_perito_agendamento.codespecialidadenatureza
                                                     ,pefetivocadastrado     => v_perito_agendamento.efetivocadastrado
                                                     ,pseqagendamento        => 0
                                                     ,ptipo_agendamento      => ptipo_agendamento
                                                     ,praj                   => vraj
                                                     ,pcdp                   => pcdp); 
      
      end if;
      --
      laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => pprotocolo
  										 			   ,pstatus    => 'AGENDADO');
      --
      update prontuariopericialoficio ppo
	  set ppo.dataagendamento = vdata_agendamento_prontuario
	  where ppo.id_oficio = poficio;
      --
      -- LISTA DE PORTARIA
      open c_perito_agenda_agendamento(vdata_agendamento.codperitoagendadetalhe);
      loop
      fetch c_perito_agenda_agendamento into vcodperitoagenda;
      EXIT WHEN c_perito_agenda_agendamento%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_perito_agenda_agendamento',sysdate,poficio,pprotocolo);
        END LOOP;
      close c_perito_agenda_agendamento;
      --
      open c_verifica_agenda_completa(vcodperitoagenda);
      loop
      fetch c_verifica_agenda_completa into vverifica;
       EXIT WHEN c_verifica_agenda_completa%NOTFOUND;
        insert into LOG_AGENDAMENTO( FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_verifica_agenda_completa',sysdate,poficio,pprotocolo);
        END LOOP;
      if c_verifica_agenda_completa%notfound then
        --
        open c_define_rotina_portaria(vprontuariopericial);
        loop
        fetch c_define_rotina_portaria into vlocal_pericia;
        EXIT WHEN c_define_rotina_portaria%NOTFOUND;
        insert into LOG_AGENDAMENTO( FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_define_rotina_portaria',sysdate,poficio,pprotocolo);
        END LOOP;
        close c_define_rotina_portaria;
        --
        open c_data_agenda_completa(vcodperitoagenda);
        loop
        fetch c_data_agenda_completa into vdata;
         EXIT WHEN c_data_agenda_completa%NOTFOUND;
        insert into LOG_AGENDAMENTO( FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_data_agenda_completa',sysdate,poficio,pprotocolo);
        END LOOP;
        close c_data_agenda_completa;
        --
        if vlocal_pericia = 2 then -- CAPITAL
          --
         
          if vdados_oficio.nomelocalprisao is not null then
            --
           -- raise_application_error(-20002,to_date(to_char(vdata,'DD/MM/YYYY'))); 
            insert into LOG_AGENDAMENTO( FLUXO,DATA)
            values ('1 prc_gera_lista_portaria_cdp_completa iniciar'||to_char(vdata,'DD/MM/YYYY'),sysdate);
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(to_char(vdata,'DD/MM/YYYY')));
            --
          else
            --
            insert into LOG_AGENDAMENTO( FLUXO,DATA)
            values ('2 prc_gera_lista_portaria_cdp_completa iniciar'||to_char(vdata,'DD/MM/YYYY'),sysdate);
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_capital_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        elsif vlocal_pericia = 3 then -- RAJ
          --
          if vreupreso = 'S' then
            if vdados_oficio.nomelocalprisao is not null then
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            end if;
            --
          else
            --
            insert into LOG_AGENDAMENTO( FLUXO,DATA)
            values ('2 prc_gera_lista_portaria_raj_completa iniciar RAJ '||to_char(vdata,'DD/MM/YYYY'),sysdate);
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_raj_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        end if;
        --
      end if;
      close c_verifica_agenda_completa;
      --
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 vdados_oficio.especialidade,
                                 vdados_oficio.natureza,
                                 poficio,
                                 ptipo_agendamento,
                                 '',
                                 pcdp,
                                 pprotocolo,
                                '',
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 '', 
                                 vraj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                'vlocal_pericia:'||vlocal_pericia,
                                'prc_agendar',
                                sysdate);
      commit;
      --
      exception
      when others then
      mensagem_erro := SQLERRM;
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 vdados_oficio.especialidade,
                                 vdados_oficio.natureza,
                                 poficio,
                                 ptipo_agendamento,
                                 '',
                                 pcdp,
                                 pprotocolo,
                                 mensagem_erro,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 '', 
                                 vraj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                'vlocal_pericia:'||vlocal_pericia,
                                'prc_agendar',
                                sysdate);
        --rollback;
      
    end prc_agendar;
    --
    procedure prc_agendar_sequencia(poficio               in number
    							                 ,pprotocolo 	          in number
    							                 ,pqtd_periciando       in number
    							                 ,ptipo_agendamento     in varchar2 default null
    							                 ,ppsiquiatria          in varchar2
                                    ,pcdp   in number default null
                                   ,pidpericiaagendamento out number) is
      --
      cursor c_prontuario_pericial(pseq_maior in number) is
        select ppo.codprontuariopericialoficio
        from prontuariopericialoficio ppo
        where ppo.idprotocolo = pprotocolo
          and ppo.id_oficio   = poficio
          and not exists (select 1
                          from periciaAgendamento pa
                          where pa.codprontuariopericialOficio = ppo.codprontuariopericialoficio
            			        and pa.seqagendamento              = pseq_maior)
        and ppsiquiatria    = 'N'
        union
        select ppo.codprontuariopericialoficio
        from prontuariopericialoficio ppo
        where ppo.idprotocolo = pprotocolo
          and ppo.id_oficio   = poficio
          and not exists (select 1
                          from periciaAgendamento pa
                          where pa.codprontuariopericialOficio = ppo.codprontuariopericialoficio
            			    and pa.seqagendamento              = pseq_maior)
          and ppsiquiatria    = 'S'
          and codprontuariopericialoficio not in nvl(laudo_pkg_agendamento.fnc_retorna_protuario_oficio_reu(poficio => poficio, pprotocolo => pprotocolo), 0);
      vprontuariopericial number;
      --
      cursor c_valida_prontuario is
        select ppo.codprontuariopericialoficio
        from prontuariopericialoficio ppo
        where ppo.idprotocolo = pprotocolo
          and ppo.id_oficio   = poficio;
      --
      vseq_maior number := 0;
      --
      vperito_agenda_datalhe number;

      mensagem_erro  VARCHAR2(1000);
      --
    begin
      --
      --raise_application_error(-20001,poficio||' - '||pprotocolo||' - '||ppsiquiatria);
      --
      open c_dados_oficio(poficio);
      LOOP
      fetch c_dados_oficio into vdados_oficio;
      EXIT WHEN c_dados_oficio%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_dados_oficio',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_dados_oficio;
      --
       insert into LOG_AGENDAMENTO(  FLUXO,DATA,PEXISTE_MESMA_ESPECINAT)
           values ('ENTROU PRC SEQUENCIAL',sysdate,vdados_oficio.localpericia);

      if vdados_oficio.localpericia = 2 then
        
         vraj := 1;
      
      else 

         insert into LOG_AGENDAMENTO(  FLUXO,DATA)
           values ('entrou na fnc_define_raj ',sysdate);

         vraj := laudo_pkg_agendamento.fnc_define_raj(pdescentralizada => vdados_oficio.descentralizada
                                                     ,praj             => vdados_oficio.raj
                                                     ,pcomarca         => vdados_oficio.comarcaprocesso);
         
      end if; 
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,PRAJ)
           values ('saiu da fnc_define_raj ',sysdate,vraj);

     --
      open c_perito_agendamento(vdados_oficio.especialidade, vdados_oficio.natureza,vraj,pcdp);
      LOOP
      fetch c_perito_agendamento into v_perito_agendamento;
      EXIT WHEN c_perito_agendamento%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_perito_agendamento',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_perito_agendamento;
      --
       insert into LOG_AGENDAMENTO(  FLUXO,DATA,PCDP)
       values ('c_perito_agendamento ',sysdate,v_perito_agendamento.codperito);

      if vdados_oficio.situacaopericiando = 2 then
		--
             insert into LOG_AGENDAMENTO(  FLUXO,DATA)
       values ('vdados_oficio.situacaopericiando = 2  vreupreso = s  ',sysdate);
       
		vreupreso := 'S';
        --
      else
        --
                 insert into LOG_AGENDAMENTO(  FLUXO,DATA)
       values ('vdados_oficio.situacaopericiando != 2  vreupreso = N  ',sysdate);
        vreupreso := 'N';
        --
	  end if;
      --
      for r_valida_prontuario in c_valida_prontuario
      loop
		--
		open c_seq_prontuario_pericial_oficio(r_valida_prontuario.codprontuariopericialoficio);
        loop
		fetch c_seq_prontuario_pericial_oficio into vseq_prontuario_pericial_oficio;
         EXIT WHEN c_seq_prontuario_pericial_oficio%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_seq_prontuario_pericial_oficio',sysdate,poficio,pprotocolo);
         END LOOP;
	    close c_seq_prontuario_pericial_oficio;
        --
        if vseq_prontuario_pericial_oficio > vseq_maior then
		  --
		  vseq_maior := vseq_prontuario_pericial_oficio;
          --
		end if;
        --
	  end loop;

      insert into LOG_AGENDAMENTO(  FLUXO,DATA)
       values ('r_agenda_sequencia vai entrar',sysdate);
      --
      for r_agenda_sequencia in (select pad.codperitoagendadetalhe
                                 ,      pad.horinicio
                                 ,	    pad.horfim
                                   from peritoagenda                pa
                                 ,      peritoagendadetalhe         pad
                                 ,      peritogeracaoagenda         pga
                                 ,      peritoperfil                pp
                                 ,      peritoespecialidadenatureza pen
                                 ,      perito                      pt
                                  where pp.codperito                       = pt.codperito
                                    and pt.indativo                        = 'Y' 
                                    and pa.codperitoagenda                 = pad.codperitoagenda
                                    and pa.qtdpericiasrestantes            >= pqtd_periciando
                                    and pa.datatendimento                  = trunc(pad.horinicio)
                                    and pad.indreservado 	                 = 'N'
                                    and pad.indencaixe	 	                 = 'N'
                                    and pad.INDATIVO 		                   = 'Y'
                                    --and pad.HORINICIO					             > sysdate !!!!
                                    and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                                       and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                                    or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                                        and pad.HORINICIO > sysdate))
                                    and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
                                    and pga.codperito                      = v_perito_agendamento.codperito
                                    and pga.codperitoperfil                = pp.codperitoperfil
                                    and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
                                    and pen.codespecialidadenatureza       = v_perito_agendamento.codespecialidadenatureza
                                    and pp.codraj                          = vraj
                                    and pcdp                               is null
                                    union 
                                    select pad.codperitoagendadetalhe
                                 ,      pad.horinicio
                                 ,	    pad.horfim
                                   from peritoagenda                pa
                                 ,      peritoagendadetalhe         pad
                                 ,      peritogeracaoagenda         pga
                                 ,      peritoperfil                pp
                                 ,      peritoespecialidadenatureza pen
                                 ,      perito                      pt
                                  where pp.codperito                       = pt.codperito
                                    and pt.indativo                        = 'Y' 
                                    and pa.codperitoagenda                 = pad.codperitoagenda
                                    and pa.qtdpericiasrestantes            >= pqtd_periciando
                                    and pa.datatendimento                  = trunc(pad.horinicio)
                                    and pad.indreservado 	                 = 'N'
                                    and pad.indencaixe	 	                 = 'N'
                                    and pad.INDATIVO 		                   = 'Y'
                                    --and pad.HORINICIO					             > sysdate !!!!
                                    and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                                       and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                                    or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                                        and pad.HORINICIO > sysdate))
                                    and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
                                    and pga.codperito                      = v_perito_agendamento.codperito
                                    and pga.codperitoperfil                = pp.codperitoperfil
                                    and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
                                    and pen.codespecialidadenatureza       = v_perito_agendamento.codespecialidadenatureza
                                    and pp.codcpd                          = pcdp
                                    and pcdp                               is not null
                                   order by 1 asc
                                 fetch first pqtd_periciando rows only)
      loop
		--
        
      insert into LOG_AGENDAMENTO(  FLUXO,DATA)
       values ('r_agenda_sequencia entrou ',sysdate);

		vdata_agendamento_prontuario := trunc(r_agenda_sequencia.horinicio);
		vdata_operacao				 := sysdate;
		--
		update peritoagendadetalhe pad
		set pad.indreservado = 'Y'
		where pad.codperitoagendadetalhe = r_agenda_sequencia.codperitoagendadetalhe;
        --
        vprontuariopericial := null;
		--
        
		open c_prontuario_pericial(vseq_maior);
        loop
        fetch c_prontuario_pericial into vprontuariopericial;
        EXIT WHEN c_prontuario_pericial%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_prontuario_pericial',sysdate,poficio,pprotocolo);
         END LOOP;
        close c_prontuario_pericial;
		--
		-- teste versionamento
		-- 
        insert into periciaAgendamento
			   (codperito
			   ,horchegada
			   ,codprontuariopericialOficio
			   ,codperitoagendadetalhe
			   ,codespecialidadenatureza
			   ,indreupreso
			   ,indativo
			   ,codpessoaacompanhante
			   ,numdocumentoacompanhante
			   ,datoperacao
			   ,codusuariooperacao
			   ,indefetivocadastrado
			   ,situacao
			   ,tipo
			   ,seqagendamento
         ,tipopericia
         ,peticionamento)
		values (v_perito_agendamento.codperito
			   ,null--r_agenda_sequencia.horinicio
			   ,vprontuariopericial
			   ,r_agenda_sequencia.codperitoagendadetalhe
			   ,v_perito_agendamento.codespecialidadenatureza
			   ,vreupreso
			   ,'Y'
			   ,null
			   ,null
			   ,vdata_operacao
			   ,nvl(v('GLOBAL_ID_USUARIO'),1)  -- Integração
			   ,v_perito_agendamento.efetivocadastrado
			   ,'AGENDADA/AGUARDANDO'
			   ,nvl(ptipo_agendamento,'P')
			   ,vseq_maior
         ,nvl(ptipo_agendamento,'P')
         ,'PENDENTE');
		--
		vid_pericia_agendamento := seq_periciaagendamento.currval;
    pidpericiaagendamento   := vid_pericia_agendamento;
		--
        insert into historico_pericia_agendamento
			   (id_periciaagendamento
			   ,codperito
			   ,codprontuariopericialoficio
			   ,codperitoagendadetalhe
			   ,codespecialidadenatureza
			   ,codusuariooperacao
			   ,dataoperacao
			   ,indefetivocadastrado
			   ,indurgente
			   ,indativo)
		values (vid_pericia_agendamento
			   ,v_perito_agendamento.codperito
			   ,vprontuariopericial
			   ,r_agenda_sequencia.codperitoagendadetalhe
			   ,v_perito_agendamento.codespecialidadenatureza
			   ,1
			   ,vdata_operacao
			   ,v_perito_agendamento.efetivocadastrado
			   ,'N'
			   ,'Y'); 
        --
        open cperitoagenda(r_agenda_sequencia.codperitoagendadetalhe);--vdata_agendamento.codperitoagendadetalhe);
        loop
        fetch cperitoagenda into vperitoagenda;
           EXIT WHEN cperitoagenda%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('cperitoagenda',sysdate,poficio,pprotocolo);
         END LOOP;
        close cperitoagenda;
 
        if nvl(ptipo_agendamento, 'P') = 'P' then
        --   
          update peritoagenda pa
             set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes -1)
           where pa.codperitoagenda = vperitoagenda.codperitoagenda;
        --          
        elsif nvl(ptipo_agendamento, 'P') = 'A' then
        --    
          update peritoagenda pa
             set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes -1)
           where pa.codperitoagenda = vperitoagenda.codperitoagenda;
        --  
        end if;
        --
        vperito_agenda_datalhe := r_agenda_sequencia.codperitoagendadetalhe;
        --     
	  end loop;
      --
          
      insert into LOG_AGENDAMENTO(  FLUXO,DATA)
       values ('r_agenda_sequencia saiuu ',sysdate);
      if ppsiquiatria = 'S' and ptipo_agendamento = 'P' then
      
         laudo_pkg_agendamento.prc_agendar_psicologia(poficio                => poficio
                                                     ,pprotocolo             => pprotocolo
                                                     ,pperito                => v_perito_agendamento.codperito
                                                     ,pdatabase              => vdata_agendamento_prontuario
                                                     ,pespecialidadenatureza => v_perito_agendamento.codespecialidadenatureza
                                                     ,pefetivocadastrado     => v_perito_agendamento.efetivocadastrado
                                                     ,pseqagendamento        => vseq_maior
                                                     ,ptipo_agendamento      => ptipo_agendamento
                                                     ,praj                   => vraj
                                                     ,pcdp                   => pcdp); 
             
      
      end if;

       insert into LOG_AGENDAMENTO(  FLUXO,DATA)
       values (' ppsiquiatria = S and ptipo_agendamento = P saiuu ',sysdate);
      --
           
      insert into LOG_AGENDAMENTO( FLUXO,DATA)
       values ('laudo_pkg_protocolo.prc_atualiza_status_protocolo vai entrarrr',sysdate);

      laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => pprotocolo
  										 			   ,pstatus    => 'AGENDADO');
      --
      update prontuariopericialoficio ppo
	  set ppo.dataagendamento = vdata_agendamento_prontuario
	  where ppo.id_oficio = poficio;
      --
      open c_perito_agenda_agendamento(vperito_agenda_datalhe); --verificar não há certeza se varios pad são para 1 peritoagenda
      loop
      fetch c_perito_agenda_agendamento into vcodperitoagenda;
          EXIT WHEN c_perito_agenda_agendamento%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_perito_agenda_agendamento',sysdate,poficio,pprotocolo);
         END LOOP;
      close c_perito_agenda_agendamento;
      --
      open c_verifica_agenda_completa(vcodperitoagenda);
      loop
      fetch c_verifica_agenda_completa into vverifica;
        EXIT WHEN c_verifica_agenda_completa%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_verifica_agenda_completa',sysdate,poficio,pprotocolo);
         END LOOP;
      if c_verifica_agenda_completa%notfound then
        --
        open c_define_rotina_portaria(vprontuariopericial);
        loop
        fetch c_define_rotina_portaria into vlocal_pericia;
        EXIT WHEN c_define_rotina_portaria%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_define_rotina_portaria',sysdate,poficio,pprotocolo);
         END LOOP;
        close c_define_rotina_portaria;
        --
        open c_data_agenda_completa(vcodperitoagenda);
        loop
        fetch c_data_agenda_completa into vdata;
         EXIT WHEN c_data_agenda_completa%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_data_agenda_completa',sysdate,poficio,pprotocolo);
         END LOOP;
        close c_data_agenda_completa;
        --
        if vlocal_pericia = 2 then -- CAPITAL
          --
          if vdados_oficio.nomelocalprisao is not null then
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          else
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_capital_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        elsif vlocal_pericia = 3 then -- RAJ
          --
          if vdados_oficio.nomelocalprisao is not null then
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          else
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_raj_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        end if;
        --
      end if;
      close c_verifica_agenda_completa;
      --
      insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 vdados_oficio.especialidade,
                                 vdados_oficio.natureza,
                                 poficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 pprotocolo,
                                '',
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 vraj, 
                                 vreupreso,
                                '', 
                                 vprontuariopericial,
                                 'vlocal_pericia:'||vlocal_pericia,
                                'prc_agendar_sequencia',
                                sysdate);
     --

      commit;
    exception
       when others then
      mensagem_erro :=  SQLERRM;
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 vdados_oficio.especialidade,
                                 vdados_oficio.natureza,
                                 poficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 pprotocolo,
                                 mensagem_erro,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 vraj, 
                                 vreupreso,
                                '', 
                                 vprontuariopericial,
                                '',
                                'prc_agendar_sequencia',
                                sysdate);
                                commit;
    end prc_agendar_sequencia;
    --
    function fnc_codigo_raj(praj in varchar2) return number is 
      --
      vraj number;
      --
    begin
      --
      if upper(praj) like '%CAPITAL%' or  upper(praj) like '%PAULO%' then
        --
        vraj := 1;
        --      
      elsif upper(praj) like '%ARAÇATUBA%' then
        --
        vraj := 2;
        --
      elsif upper(praj) like '%BAURU%' then
        --
        vraj := 3;
        --
      elsif upper(praj) like '%CAMPINAS%' then
        --
        vraj := 4;
        --
      elsif upper(praj) like '%PRESIDENTE%' then
        --
        vraj := 5;
        --
      elsif upper(praj) like '%RIBEIRÃO%' then
        --
        vraj := 6;
        --
      elsif upper(praj) like '%SANTOS%' then
        --
        vraj := 7;
        --
      elsif upper(praj) like '%RIO PRETO%' then
        --
        vraj := 8;
        --
      elsif upper(praj) like '%SOROCABA%' then
        --
        vraj := 10;
        --
      elsif upper(praj) like '%SOROCABA%' then
        --
        vraj := 29;
        --
      end if;
      --
      if vraj is null then
         --
         if upper(praj) = '1' then
            --
            vraj := 1;
            --
         elsif upper(praj) = '2' then
            --
            vraj := 2;
            --
         elsif upper(praj) = '3' then
            --
            vraj := 3;
            --
         elsif upper(praj) = '4' then
            --
            vraj := 4;
            --
         elsif upper(praj) = '5' then
            --
            vraj := 5;
            --
         elsif upper(praj) = '6' then
            --
            vraj := 6;
            --
         elsif upper(praj) = '7' then
            --
            vraj := 7;
            --
         elsif upper(praj) = '8' then
            --
            vraj := 8;
            --
         elsif upper(praj) = '9' then
            --
            vraj := 9;
            --
         elsif upper(praj) = '10' then
            --
            vraj := 10;
            --
         end if;
      --
      end if;
      --
      return vraj;
      --
    end fnc_codigo_raj;
    --
    function fnc_define_raj(pdescentralizada in varchar2
                           ,praj             in number
                           ,pcomarca         in varchar2) return number is 
      --
      vraj number;
      --
    begin
      --
      if pdescentralizada = 'S' then
		--
		vraj := laudo_pkg_agendamento.fnc_codigo_raj(praj => praj);
        --
        if vraj = 5 then -- Presidente Prudente
          --
          if upper(pcomarca) like '%DRACENA%' or upper(pcomarca) like '%JUNQUEIRÓPOLIS%' or upper(pcomarca) like '%PACAEMBU%' or upper(pcomarca) like '%PANORAMA%' or upper(pcomarca) like '%TUPI PAULISTA%'  then
		    --
		    vraj := 29; -- Dracena
		    --
		  else
		    --
		    vraj := 5;
		    --
		  end if;
          --
        end if;
        --
      else
        --
        vraj := 1; -- Capital
        --
	  end if;
      --
      return vraj;
      --
    end fnc_define_raj;
    --
 
 
   function fnc_define_cdp(pcdp in varchar2 ) return number is 
                         
      --
      vcdp    number;
      vexists varchar2(1);
      --
    begin
      
     select nvl((select 'S'
                   from deparacdp
                  where translate(trim(upper(nomelocalcdp)),
                         'ŠŽšžŸÁÇÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕËÜÏÖÑÝåáçéíóúàèìòùâêîôûãõëüïöñýÿ0123456789-.;:/\,–)(”“ ','SZszYACEIOUAEIOUAEIOUAOEUIONYaaceiouaeiouaeiouaoeuionyy')    
                   like   '%'|| translate(trim(upper(pcdp)),
                           'ŠŽšžŸÁÇÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕËÜÏÖÑÝåáçéíóúàèìòùâêîôûãõëüïöñýÿ0123456789-.;:/\,–)(”“ ',
                           'SZszYACEIOUAEIOUAEIOUAOEUIONYaaceiouaeiouaeiouaoeuionyy')||'%'
                   and rownum = 1 ),'N') into vexists from dual;   
      --
      if vexists = 'S' then
        
      select codcdp
      into   vcdp 
      from   deparacdp 
      where  translate(trim(upper(nomelocalcdp)),
      'ŠŽšžŸÁÇÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕËÜÏÖÑÝåáçéíóúàèìòùâêîôûãõëüïöñýÿ0123456789-.;:/\,–)(”“ ','SZszYACEIOUAEIOUAEIOUAOEUIONYaaceiouaeiouaeiouaoeuionyy')
                 
      like   '%'|| translate(trim(upper(pcdp)),
                 'ŠŽšžŸÁÇÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕËÜÏÖÑÝåáçéíóúàèìòùâêîôûãõëüïöñýÿ0123456789-.;:/\,–)(”“ ',
                 'SZszYACEIOUAEIOUAEIOUAOEUIONYaaceiouaeiouaeiouaoeuionyy')||'%'
      and        rownum = 1 ;          
      --
      end if;
      
      return vcdp;
      --
    end fnc_define_cdp;
    --
 
 
    function fnc_valida_hora_agenda (phorainicio in date
                                    ,phorafim    in date
                                    ,pcodperito  in number) return varchar2 is
      --
      vexists varchar2(2);
      --
    begin
      --
      select nvl ((select 'S'
                  from peritoagendadetalhe ad
                  ,    peritoagenda pa
                  ,    peritogeracaoagenda pg
                  where ad.codperitoagenda        = pa.codperitoagenda
                    and pa.codperitogeracaoagenda = pg.codperitogeracaoagenda
                    and pg.codperito              = pcodperito
                    and (ad.INDRESERVADO = 'Y' OR ad.INDENCAIXE = 'Y')
                    and (to_date(to_char(horinicio,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(phorainicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(phorafim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') 
                        or to_date(to_char(horfim,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(phorainicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(phorafim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') 
                        or to_date(to_char(phorainicio,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(horinicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(horfim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')
                        or to_date(to_char(phorafim,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(horinicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(horfim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS'))
                    and rownum = 1),'N') into vexists from dual;
      --
      return (vexists); -- 'S'= true, 'N' = false
      --
    end fnc_valida_hora_agenda;
    --
    function fnc_codigo_data_trancada (phorainicio in date
                                      ,phorafim    in date
                                      ,pcodperito  in number) return varchar2 is
      --
      vcodigo_data_trancada varchar2(4000);
      --
    begin
      --
      select listagg(codperitoagendadetalhe, ',')
              within group(order by codperitoagendadetalhe desc) into vcodigo_data_trancada
      from peritoagendadetalhe ad
      ,    peritoagenda pa
      ,    peritogeracaoagenda pg
      where ad.codperitoagenda        = pa.codperitoagenda
        and pa.codperitogeracaoagenda = pg.codperitogeracaoagenda
        and pg.codperito              = pcodperito
        and (to_date(to_char(horinicio,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(phorainicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(phorafim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')
             or to_date(to_char(horfim,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(phorainicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(phorafim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')
             or to_date(to_char(phorainicio,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(horinicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(horfim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS')
             or to_date(to_char(phorafim,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') between to_date(to_char(horinicio ,'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS') and to_date(to_char(horfim , 'DD/MM/YYYY HH24:MI:SS'),'DD/MM/YYYY HH24:MI:SS'));
      --
      return (vcodigo_data_trancada); 
      --
    end fnc_codigo_data_trancada;
    --
    procedure prc_tranca_data(pcodperito       in number
                             ,pdatainicio      in date
                             ,pdatafim         in date
                             ,phorainicio      in varchar2
                             ,phorafim         in varchar2
                             ,pmotivo          in number
                             ,pcoddatatrancada in number) is
      --
      vdata       varchar2(20);
      vcod        varchar2(4000);
      vdatainicio number;
      vdatafim    number;
      --
      vhora_inicio  date;
      vhora_inicio1 number;
      vhora_inicio2 varchar2(100);
      vhora_fim     date;
      vhora_fim1    number;
      vhora_fim2    varchar2(100);
      --
    begin
      --
      vdatainicio := to_number(to_char(to_date(pdatainicio,'DD/MM/YYYY'),'j'));
      vdatafim    := to_number(to_char(to_date(pdatafim,'DD/MM/YYYY'),'j'));
      --
      if pmotivo = 0 then -- Férias
        --
        update peritoagendadetalhe pad
        set pad.codperitoagendadatastrancadas = pcoddatatrancada
        where (trunc(pad.horinicio) between pdatainicio and pdatafim
               or trunc(pad.horfim) between pdatainicio and pdatafim)
          and exists (select 1 
                      from peritoagenda        pa 
                      ,    peritogeracaoagenda pga
                      where pa.codperitoagenda        = pad.codperitoagenda
                        and pa.codperitogeracaoagenda = pga.codperitogeracaoagenda
                        and pga.codperito             = pcodperito);
        --
      elsif pmotivo = 1 then -- Outros
        --
        for c1 in vdatainicio .. vdatafim 
        loop
          --
          vdata := to_char(to_date(to_number(c1), 'JSP'), 'DD/MM/YYYY');
          --
 
          vhora_inicio  := to_date((vdata ||' '|| phorainicio),'DD/MM;/YYYY HH24:MI:SS');
          vhora_fim     := to_date((vdata ||' '|| phorafim),'DD/MM;/YYYY HH24:MI:SS');
          --
          vhora_inicio1 := ((to_number(to_char(vhora_inicio, 'HH24'))* 3600) + (to_number(to_char(vhora_inicio, 'MI'))*60) + to_number(to_char(vhora_inicio, 'SS'))) + 1 ;
          vhora_inicio2 := (to_char(trunc(vhora_inicio1/60/60), 'FM9900') ||':'|| to_char(trunc(mod(vhora_inicio1,3600)/60),'FM00') ||':'|| to_char(trunc(mod(vhora_inicio1,60)),'FM00') );
          --
          vhora_fim1    := ((to_number(to_char(vhora_fim, 'HH24'))* 3600) + (to_number(to_char(vhora_fim, 'MI'))*60) + to_number(to_char(vhora_fim, 'SS'))) - 1 ;
          vhora_fim2    := (to_char(trunc(vhora_fim1/60/60), 'FM9900') ||':'|| to_char(trunc(mod(vhora_fim1,3600)/60),'FM00') ||':'|| to_char(trunc(mod(vhora_fim1,60)),'FM00'));      
          -- 
          --Raise_Application_Error(-20001,'INICIO '|| vdata||' '||vhora_fim2); 
          
          vcod := laudo_pkg_agendamento.fnc_codigo_data_trancada(phorainicio => to_date(vdata||' '||vhora_inicio2,'DD/MM/YYYY HH24:MI:SS')--to_date(vdata||' '||phorainicio,'DD/MM/YYYY HH24:MI:SS')
                                                                ,phorafim    => to_date(vdata||' '||vhora_fim2,'DD/MM/YYYY HH24:MI:SS')--to_date(vdata||' '||phorafim,'DD/MM/YYYY HH24:MI:SS')
                                                                ,pcodperito  => pcodperito);
          --
          if vcod is not null then
            --
            for r_data_trancada in (select regexp_substr(vcod,'[^,]+',1,level) codigo_data_trancada
                                    from dual
                                    connect by level <= length(regexp_replace(vcod,'[^,]+')) + 1) 
            loop
              --
              update peritoagendadetalhe pda
                 set pda.codperitoagendadatastrancadas = pcoddatatrancada,
                     pda.indativo                      = 'N'
              where pda.codperitoagendadetalhe = to_number(r_data_trancada.codigo_data_trancada);
              --
            end loop;
            --  
          end if;
          --
        end loop;
        --
      end if;  
      --
    end prc_tranca_data;
    --
    procedure prc_agendamento_prontuario(pprotocolo                in number,
                                         poficio                   in number,
                                         pespecialidade            in number,
                                         pnatureza                 in number,
                                         praj                      in number,   
                                         pqtdpericiando            in number,
                                         psituacao_periciando      in varchar2 default null,
                                         ppsiquiatria              in varchar2,
                                         ptipo_agendamento         in varchar2 default null,
                                         pprontuariopericialoficio in number default null,
                                         pidpericiaagendamento     out number) is
 
      --
      verro          varchar2(1);
      vqtdpericiando number := pqtdpericiando;
      vpsicologia    varchar2(10);
      vvalida        varchar2(10);
      vqtpericiando  number;
      -- 
    begin
      --
      update oficio o
         set o.especialidade = pespecialidade,
             o.natureza      = pnatureza
       where o.id_oficio     = poficio ;
       commit;
       
      if (ptipo_agendamento = 'A' and  ppsiquiatria = 'S') or (ptipo_agendamento = 'A' and  pqtdpericiando > 1) then
      
          vqtdpericiando := 1;
   
      end if;  
      
      if ptipo_agendamento = 'P' and  ppsiquiatria = 'S' then
      
        laudo_pkg_agendamento.prc_valida_psicologia(pespecialidade        => pespecialidade,
                                                    pnatureza             => pnatureza,
                                                    poficio               => poficio,
                                                    ptipo_agendamento     => ptipo_agendamento,
                                                    pqtdpericiando        => pqtdpericiando,
                                                    pprotocolo            => pprotocolo,
                                                    perro                 => verro,
                                                    ppsicologia           => vpsicologia,
                                                    pvalida               => vvalida,
                                                    pidpericiaagendamento => pidpericiaagendamento,
                                                    pqtpericiando         => vqtpericiando);
                                                    
            --raise_application_error(-20001,vvalida ||' - '|| verro ||' - '||vpsicologia ||' - '|| vqtpericiando);
        
        if vvalida = 'S'  and  verro <> 'S' then
          
            laudo_pkg_agendamento.prc_valida_agendamento(pid_oficio                => poficio
                                                        ,pespecialidade            => pespecialidade
                                                        ,pnatureza                 => pnatureza
                                                        ,praj                      => praj
                                                        ,pqtd_periciando           => vqtpericiando
                                                        ,psituacao_periciando      => psituacao_periciando
                                                        ,ppsiquiatria              => vpsicologia 
                                                        ,ptipo_agendamento         => ptipo_agendamento 
                                                        ,pprontuariopericialoficio =>pprontuariopericialoficio
                                                       --retorno
                                                        ,perro                     => verro
                                                        ,pexiste_mesma_especinat   => vmesma_especialidade_natureza
                                                        ,pidpericiaagendamento      =>pidpericiaagendamento);
        
            --
            if nvl(verro, 'N') = 'N' then 
              --
              if vqtpericiando > 1 then
                --
                laudo_pkg_agendamento.prc_agendar_sequencia(poficio               => poficio
                                                           ,pprotocolo            => pprotocolo
                                                           ,pqtd_periciando       => vqtpericiando
                                                           ,ptipo_agendamento     => ptipo_agendamento
                                                           ,ppsiquiatria          => vpsicologia
                                                           ,pidpericiaagendamento => pidpericiaagendamento);
                --
              else
                --
                if vmesma_especialidade_natureza = 'N' then
                  --
                  laudo_pkg_agendamento.prc_agendar(poficio           => poficio
                                                   ,pprotocolo        => pprotocolo
                                                   ,ptipo_agendamento => ptipo_agendamento
                                                   ,ppsiquiatria      => vpsicologia
                                                   ,pprontuariopericialoficio =>pprontuariopericialoficio
                                                   ,pidpericiaagendamento => pidpericiaagendamento );
                  --
                end if;
                --
              end if;
              --
            end if;
              
        end if;
        
      else
       --
       --raise_application_error(-20001,'1-'||ppsiquiatria);
        laudo_pkg_agendamento.prc_valida_agendamento(pid_oficio                => poficio
                                                    ,pespecialidade            => pespecialidade
                                                    ,pnatureza                 => pnatureza
                                                    ,praj                      => praj
                                                    ,pqtd_periciando           => vqtdpericiando
                                                    ,psituacao_periciando      => psituacao_periciando
                                                    ,ppsiquiatria              => ppsiquiatria 
                                                    ,ptipo_agendamento         => ptipo_agendamento 
                                                    ,pprontuariopericialoficio =>pprontuariopericialoficio
                                                   --retorno
                                                    ,perro                     => verro
                                                    ,pexiste_mesma_especinat   => vmesma_especialidade_natureza
                                                    ,pidpericiaagendamento      =>pidpericiaagendamento);
        
        --
        if nvl(verro, 'N') = 'N' then 
          --
          if vqtdpericiando > 1 then
            --
            laudo_pkg_agendamento.prc_agendar_sequencia(poficio               => poficio
                                                       ,pprotocolo            => pprotocolo
                                                       ,pqtd_periciando       => vqtdpericiando
                                                       ,ptipo_agendamento     => ptipo_agendamento
                                                       ,ppsiquiatria          => ppsiquiatria
                                                       ,pidpericiaagendamento => pidpericiaagendamento);
            --
          else
            --
            if vmesma_especialidade_natureza = 'N' then
              --
              laudo_pkg_agendamento.prc_agendar(poficio           => poficio
                                               ,pprotocolo        => pprotocolo
                                               ,ptipo_agendamento => ptipo_agendamento
                                               ,ppsiquiatria      => ppsiquiatria
                                               ,pprontuariopericialoficio =>pprontuariopericialoficio
                                               ,pidpericiaagendamento => pidpericiaagendamento );
              --
            end if;
            --
          end if;
          --
        end if;
      -- 
      end if;
 
      commit;
      
    end prc_agendamento_prontuario;
    --
    procedure prc_remanejar_agenda(ppericia_agendamento            in number
    							  ,pperito_agenda_detalhe 		   in number
    							  ,pperito_remanejar			   in number
    							  ,pperito_agenda_detalhe_remanejar in number
    							  ,pperito_perfil_remanejar		    in number) is
      --
      cursor c_dados_agendamento_remanejado is
        select pa.codperito
        , 	   pa.codprontuariopericialoficio
        ,      pa.indreupreso
        , 	   pa.indativo
        , 	   pa.codpessoaacompanhante
        , 	   pa.numdocumentoacompanhante
        , 	   pa.situacaopericiando
        ,      pa.tipo
        ,      pa.tipopericia
        ,      o.nomelocalprisao
        from periciaagendamento pa
        ,    prontuariopericialoficio ppo 
        ,    oficio                   o 
        where pa.id_periciaagendamento       = ppericia_agendamento
          and pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
          and ppo.id_oficio                  = o.id_oficio;
      vdados_agendamento_remanejado c_dados_agendamento_remanejado%rowtype;
      --
      cursor c_dados_perito_remanejar is
        select case
				 when pp.indefetivo = 'Y' and pp.indcadastrado = 'Y' then 'Efetivo | Cadastrado'
				 when pp.indefetivo = 'Y' then 'Efetivo'
				 when pp.indcadastrado = 'Y' then 'Cadastrado'
				 when pp.indcredenciado = 'Y' then 'Credenciado'
			   end situacao
        ,	   case 
               when pp.indefetivo = 'Y' or pp.indcadastrado = 'Y' then 'Y'
               else 'N' 
              end efetivo_cadastrado
        ,	  pen.codespecialidadenatureza
        from peritoperfil pp
        ,    peritoespecialidadenatureza pen
        where pp.codperitoperfil = pperito_perfil_remanejar
          and pp.codperitoespecialidadenatureza = pen.codperitoespecialidadenatureza;
      vdados_perito_remanejar c_dados_perito_remanejar%rowtype;
      --
      cursor c_verifica_qtd_sequencia is
        select count(p.codperitoagendadetalhe) qtd
	    from periciaagendamento p
	    where p.codperitoagendadetalhe = pperito_agenda_detalhe;
      vverifica_qtd_sequencia number;
      --
      cursor c_pericia_agendamento_sequencia is 
        select p.id_periciaagendamento
        ,      p.codperito
        , 	   p.codprontuariopericialoficio
        ,      p.indreupreso
        , 	   p.indativo
        , 	   p.codpessoaacompanhante
        , 	   p.numdocumentoacompanhante
        , 	   p.situacaopericiando
        ,      p.tipo
        ,      p.tipopericia
	    from periciaagendamento p
	    where p.codperitoagendadetalhe = pperito_agenda_detalhe;
      --
      cursor c_datas is 
        select p1.horinicio data_antiga
        ,      p2.horinicio nova_data
	    from peritoagendadetalhe p1
        ,    peritoagendadetalhe p2
	    where p1.codperitoagendadetalhe = pperito_agenda_detalhe
          and p2.codperitoagendadetalhe = pperito_agenda_detalhe_remanejar;
      vdatas c_datas%rowtype;
      --
      cursor c_dados_processo_periciano is
        select po.numprocesso vnumeroprocesso,
               po.idprontuariopericial vprontuario,
               pe.nomepericiando vnomepericiando,
               v.nomevara vvara,
               r.desraj venderecopericia,
                 (select TO_CHAR(DESC_FORO ||' '| | DESC_VARA ||' '|| DESC_COMARCA)
               from DEPARA_RAJ_COMARCA_FORO_VARA_MUNI  
               where COD_VARA = o.VARA 
               and   COD_RAJ = r.CODRAJ
               and   COD_FORO = o.foro
               and rownum = 1
               	) juiz
         
        from periciaagendamento 	  p
        ,    prontuariopericialoficio po
        ,    oficiopericiando 		  pe
        ,    oficio 				  o
        ,    foro_vara 				  v
        ,    raj 					  r
        where po.id_oficio 					= o.id_oficio
          and o.vara 						= v.codvara
          and o.foro 						= v.codforo
          and o.raj  						= r.codraj
          and p.codprontuariopericialoficio = po.codprontuariopericialoficio
          and po.id_oficio_periciando  		= pe.id_oficio_periciando
          and p.codperitoagendadetalhe 		= pperito_agenda_detalhe;
        vdados_processo_periciano c_dados_processo_periciano%rowtype;
      --
      vprontuario number;
      --
    begin
      --
      open c_dados_processo_periciano;
      fetch c_dados_processo_periciano into vdados_processo_periciano;
      close c_dados_processo_periciano;
      --
      open c_dados_perito_remanejar;
      fetch c_dados_perito_remanejar into vdados_perito_remanejar;
      close c_dados_perito_remanejar;
      --
      open c_verifica_qtd_sequencia;
      fetch c_verifica_qtd_sequencia into vverifica_qtd_sequencia;
      close c_verifica_qtd_sequencia;
      --
      if vverifica_qtd_sequencia > 1 then
		--
        for r_verifica_sequencia in c_pericia_agendamento_sequencia 
        loop
          --
          delete periciaagendamento pa
          where pa.id_periciaagendamento = r_verifica_sequencia.id_periciaagendamento;
          --
		  insert into periciaagendamento
				 (codperito
				 ,horchegada
				 ,codprontuariopericialoficio
				 ,codperitoagendadetalhe
				 ,codespecialidadenatureza
				 ,indreupreso
				 ,indativo
				 ,codpessoaacompanhante
				 ,numdocumentoacompanhante
				 ,datoperacao
				 ,codusuariooperacao
				 ,indefetivocadastrado
				 ,situacaoperito
				 ,situacao
				 ,tipo
				 ,situacaopericiando
				 ,perito_remanejado
				 ,peritoagendadetalhe_remanejado
         ,tipopericia
         ,peticionamento)
		  values (pperito_remanejar
				 ,null -- É atualizado somente quando o perito comparecer
				 ,r_verifica_sequencia.codprontuariopericialoficio
				 ,pperito_agenda_detalhe_remanejar
				 ,vdados_perito_remanejar.codespecialidadenatureza
				 ,r_verifica_sequencia.indreupreso
				 ,r_verifica_sequencia.indativo
				 ,r_verifica_sequencia.codpessoaacompanhante
				 ,r_verifica_sequencia.numdocumentoacompanhante
				 ,sysdate
				 ,nvl(v('GLOBAL_ID_USUARIO'),1)
				 ,vdados_perito_remanejar.efetivo_cadastrado
				 ,vdados_perito_remanejar.situacao
				 ,'AGENDADA/AGUARDANDO'
				 ,r_verifica_sequencia.tipo
				 ,r_verifica_sequencia.situacaopericiando
				 ,r_verifica_sequencia.codperito
				 ,pperito_agenda_detalhe
         ,r_verifica_sequencia.tipopericia
         ,'PENDENTE');
          --
          open cperitoagenda(pperito_agenda_detalhe);
      	  fetch cperitoagenda into vperitoagenda;
      	  close cperitoagenda;
          --
          open cperitoagenda(pperito_agenda_detalhe_remanejar);
      	  fetch cperitoagenda into vperitoagenda_nova;
      	  close cperitoagenda;
          --
          if nvl(r_verifica_sequencia.tipo, 'P') = 'P' then
			--
			update peritoagenda pa
			   set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes + 1)
			 where pa.codperitoagenda = vperitoagenda.codperitoagenda;
			--
			update peritoagenda pa
			   set pa.qtdpericiasrestantes = (vperitoagenda_nova.qtdpericiasrestantes - 1)
			 where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
			--
		  elsif nvl(r_verifica_sequencia.tipo, 'P') = 'A' then
			--
			update peritoagenda pa
			   set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes + 1)
			 where pa.codperitoagenda = vperitoagenda.codperitoagenda;
			--
			update peritoagenda pa
			   set pa.qtdavaliacoesrestantes = (vperitoagenda_nova.qtdavaliacoesrestantes - 1)
			 where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
			--
		  end if;
          --
          vprontuario := r_verifica_sequencia.codprontuariopericialoficio;
          --
        end loop;
        --
        update peritoagendadetalhe pad
        set pad.indreservado = 'Y'
        where pad.codperitoagendadetalhe = pperito_agenda_detalhe_remanejar;
        --
        update peritoagendadetalhe pad
        set pad.indreservado = 'N'
        where pad.codperitoagendadetalhe = pperito_agenda_detalhe;
        --
        open c_perito_agenda_agendamento(pperito_agenda_detalhe_remanejar); --verificar não há certeza se varios pad são para 1 peritoagenda
        fetch c_perito_agenda_agendamento into vcodperitoagenda;
        close c_perito_agenda_agendamento;
        --
        open c_verifica_agenda_completa(vcodperitoagenda);
        fetch c_verifica_agenda_completa into vverifica;
        if c_verifica_agenda_completa%notfound then
          --
          open c_define_rotina_portaria(vprontuario);
          fetch c_define_rotina_portaria into vlocal_pericia;
          close c_define_rotina_portaria;
          --
          open c_data_agenda_completa(vcodperitoagenda);
          fetch c_data_agenda_completa into vdata;
          close c_data_agenda_completa;
          --
          if vlocal_pericia = 2 then -- CAPITAL
            --
            if vdados_oficio.nomelocalprisao is not null then
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            else
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_capital_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            end if;
            --
          elsif vlocal_pericia = 3 then -- RAJ
            --
            if vdados_oficio.nomelocalprisao is not null then
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            else
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_raj_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            end if;
            --
          end if;
          --
        end if;
        close c_verifica_agenda_completa;
        --
      else
        --
        open c_dados_agendamento_remanejado;
        fetch c_dados_agendamento_remanejado into vdados_agendamento_remanejado;
        close c_dados_agendamento_remanejado;
        --
		insert into periciaagendamento
			   (codperito
			   ,horchegada
			   ,codprontuariopericialoficio
			   ,codperitoagendadetalhe
			   ,codespecialidadenatureza
			   ,indreupreso
			   ,indativo
			   ,codpessoaacompanhante
			   ,numdocumentoacompanhante
			   ,datoperacao
			   ,codusuariooperacao
			   ,indefetivocadastrado
			   ,situacaoperito
			   ,situacao
			   ,tipo
			   ,situacaopericiando
			   ,perito_remanejado
			   ,peritoagendadetalhe_remanejado
         ,tipopericia
         ,peticionamento)
		values (pperito_remanejar
			   ,null -- É atualizado somente quando o perito comparecer
			   ,vdados_agendamento_remanejado.codprontuariopericialoficio
			   ,pperito_agenda_detalhe_remanejar 
			   ,vdados_perito_remanejar.codespecialidadenatureza
			   ,vdados_agendamento_remanejado.indreupreso
			   ,vdados_agendamento_remanejado.indativo
			   ,vdados_agendamento_remanejado.codpessoaacompanhante
			   ,vdados_agendamento_remanejado.numdocumentoacompanhante
			   ,sysdate
			   ,nvl(v('GLOBAL_ID_USUARIO'),1)
			   ,vdados_perito_remanejar.efetivo_cadastrado
			   ,vdados_perito_remanejar.situacao
			   ,'AGENDADA/AGUARDANDO'
			   ,vdados_agendamento_remanejado.tipo
			   ,vdados_agendamento_remanejado.situacaopericiando
			   ,vdados_agendamento_remanejado.codperito
			   ,pperito_agenda_detalhe
         ,vdados_agendamento_remanejado.tipopericia
         ,'PENDENTE REMANEJAMENTO');
        --
        open cperitoagenda(pperito_agenda_detalhe);
      	fetch cperitoagenda into vperitoagenda;
      	close cperitoagenda;
        --
        open cperitoagenda(pperito_agenda_detalhe_remanejar);
      	fetch cperitoagenda into vperitoagenda_nova;
      	close cperitoagenda;
        --
        if nvl(vdados_agendamento_remanejado.tipo, 'P') = 'P' then
		  --
		  update peritoagenda pa
		  set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes + 1)
		  where pa.codperitoagenda = vperitoagenda.codperitoagenda;
		  --
		  update peritoagenda pa
		  set pa.qtdpericiasrestantes = (vperitoagenda_nova.qtdpericiasrestantes - 1)
		  where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
		  --
		elsif nvl(vdados_agendamento_remanejado.tipo, 'P') = 'A' then
		  --
		  update peritoagenda pa
		  set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes + 1)
		  where pa.codperitoagenda = vperitoagenda.codperitoagenda;
		  --
		  update peritoagenda pa
		  set pa.qtdavaliacoesrestantes = (vperitoagenda_nova.qtdavaliacoesrestantes - 1)
		  where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
		  --
		end if;
        --
        open c_perito_agenda_agendamento(pperito_agenda_detalhe_remanejar); --verificar não há certeza se varios pad são para 1 peritoagenda
        fetch c_perito_agenda_agendamento into vcodperitoagenda;
        close c_perito_agenda_agendamento;
        --
        open c_verifica_agenda_completa(vcodperitoagenda);
        fetch c_verifica_agenda_completa into vverifica;
        if c_verifica_agenda_completa%notfound then
          --
          open c_define_rotina_portaria(vdados_agendamento_remanejado.codprontuariopericialoficio);
          fetch c_define_rotina_portaria into vlocal_pericia;
          close c_define_rotina_portaria;
          --
          open c_data_agenda_completa(vcodperitoagenda);
          fetch c_data_agenda_completa into vdata;
          close c_data_agenda_completa;
          --
          if vlocal_pericia = 2 then -- CAPITAL
            --
            if vdados_oficio.nomelocalprisao is not null then
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            else
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_capital_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            end if;
            --
          elsif vlocal_pericia = 3 then -- RAJ
            --
            if vdados_oficio.nomelocalprisao is not null then
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            else
              --
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_raj_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
              --
            end if;
            --
          end if;
          --
        end if;
        close c_verifica_agenda_completa;
        --
	  end if;
      --
      delete periciaagendamento pa
      where pa.id_periciaagendamento = ppericia_agendamento;
      --
      update peritoagendadetalhe pad
      set pad.indreservado = 'Y'
      where pad.codperitoagendadetalhe = pperito_agenda_detalhe_remanejar;
      --
      update peritoagendadetalhe pad
      set pad.indreservado = 'N'
      where pad.codperitoagendadetalhe = pperito_agenda_detalhe;
      --
      open c_datas;
      fetch c_datas into vdatas;
      close c_datas;
      --
      /*if vdatas.data_antiga != vdatas.nova_data then
        --
        V_OFICIO :=  LAUDO_PKG_API_PDF.FNC_DADOS_REPORT_VIEW(''
                                                            ,vdados_processo_periciano.vnomePericiando,vdados_processo_periciano.venderecoPericia
                                                            ,vdados_processo_periciano.vnumeroprocesso
                                                            ,''
                                                            ,''
                                                            ,''
                                                            ,vdados_processo_periciano.vprontuario
                                                            ,''
                                                            ,''
                                                            ,''
                                                            ,vdados_processo_periciano.juiz
                                                            , ''
                                                            ,to_char(vdatas.nova_data, 'DD/MM/YYYY') 
                                                            ,to_Char(vdatas.nova_data, 'HH24:SS')
                                                            ,''
                                                            ,''
                                                            ,''
                                                            , 'remanejamento'
                                                            ,''
                                                            ,''
                                                            ,''
                                                            ,''
                                                            ,'');
        --'cod 807 oficios de  agendamentos TESTEEEEE'
        APEX_JSON.PARSE(V_OFICIO);
        --
        v_arquivoAssinado := apex_json.GET_CLOB (p_path => 'oficioBase64'); 
        --
        if v_arquivoAssinado is not null  then
          --
          if (laudo_pkg_util.fnc_retorna_parametro('AMBIENTE')) != 'DEV' then
            
            LAUDO_PKG_SERVICO.prc_peticionamento(vdados_processo_periciano.vnumeroprocesso,v_arquivoAssinado,'1205');-- prd 
          
          else
            
           LAUDO_PKG_SERVICO.prc_peticionamento(vdados_processo_periciano.vnumeroprocesso,v_arquivoAssinado,'807'); --hml
          
          end if; 
          --
        end if;
        --                
      end if;*/ 
      --
    end prc_remanejar_agenda;
    --
    procedure prc_remanejar_agenda_urgente(ppericia_agendamento     in number
    							          ,pperito_agenda_detalhe 	in number
    							          ,pperito_remanejar		in number
                                          ,phorario_inicio          in date
                                          ,pintervalo_atendimento   in number 
    							          ,pperito_perfil_remanejar	in number) is
      --
      cursor c_dados_agendamento_remanejado is
        select pa.codperito
        , 	   pa.codprontuariopericialoficio
        ,      pa.indreupreso
        , 	   pa.indativo
        , 	   pa.codpessoaacompanhante
        , 	   pa.numdocumentoacompanhante
        , 	   pa.situacaopericiando
        ,      pa.tipo
        from periciaagendamento pa 
        where pa.id_periciaagendamento = ppericia_agendamento;
      vdados_agendamento_remanejado c_dados_agendamento_remanejado%rowtype;
      --
      cursor c_dados_perito_remanejar is
        select case
				 when pp.indefetivo = 'Y' and pp.indcadastrado = 'Y' then 'Efetivo | Cadastrado'
				 when pp.indefetivo = 'Y' then 'Efetivo'
				 when pp.indcadastrado = 'Y' then 'Cadastrado'
				 when pp.indcredenciado = 'Y' then 'Credenciado'
			   end situacao
        ,	   case 
               when pp.indefetivo = 'Y' or pp.indcadastrado = 'Y' then 'Y'
               else 'N' 
              end efetivo_cadastrado
        ,	  pen.codespecialidadenatureza
        from peritoperfil pp
        ,    peritoespecialidadenatureza pen
        where pp.codperitoperfil = pperito_perfil_remanejar
          and pp.codperitoespecialidadenatureza = pen.codperitoespecialidadenatureza;
      vdados_perito_remanejar c_dados_perito_remanejar%rowtype;
      --
      cursor c_verifica_qtd_sequencia is
        select count(p.codperitoagendadetalhe) qtd
	    from periciaagendamento p
	    where p.codperitoagendadetalhe = pperito_agenda_detalhe;
      vverifica_qtd_sequencia number;
      --
      cursor c_pericia_agendamento_sequencia is 
        select p.id_periciaagendamento
        ,      p.codperito
        , 	   p.codprontuariopericialoficio
        ,      p.indreupreso
        , 	   p.indativo
        , 	   p.codpessoaacompanhante
        , 	   p.numdocumentoacompanhante
        , 	   p.situacaopericiando
        ,      p.tipo
	    from periciaagendamento p
	    where p.codperitoagendadetalhe = pperito_agenda_detalhe;
      --
      cursor c_datas(pagenda_urgente in number) is 
        select p1.horinicio data_antiga
        ,      p2.horinicio nova_data
	    from peritoagendadetalhe p1
        ,    peritoagendadetalhe p2
	    where p1.codperitoagendadetalhe = pperito_agenda_detalhe
          and p2.codperitoagendadetalhe = pagenda_urgente;
      vdatas c_datas%rowtype;
      --
      cursor c_dados_processo_periciano is
        select po.numprocesso vnumeroprocesso,
               po.idprontuariopericial vprontuario,
               pe.nomepericiando vnomepericiando,
               v.nomevara vvara,
               r.desraj venderecopericia
        from periciaagendamento 	  p
        ,    prontuariopericialoficio po
        ,    oficiopericiando 		  pe
        ,    oficio 				  o
        ,    foro_vara 				  v
        ,    raj 					  r
        where po.id_oficio 					= o.id_oficio
          and o.vara 						= v.codvara
          and o.foro 						= v.codforo
          and o.raj  						= r.codraj
          and p.codprontuariopericialoficio = po.codprontuariopericialoficio
          and po.id_oficio_periciando  		= pe.id_oficio_periciando
          and p.codperitoagendadetalhe 		= pperito_agenda_detalhe;
        vdados_processo_periciano c_dados_processo_periciano%rowtype;
      --
      vid_agenda_urgente number;
      vhora_fim          date;
      --
    begin
      --
      open c_dados_processo_periciano;
      fetch c_dados_processo_periciano into vdados_processo_periciano;
      close c_dados_processo_periciano;
      --
      open c_dados_perito_remanejar;
      fetch c_dados_perito_remanejar into vdados_perito_remanejar;
      close c_dados_perito_remanejar;
      --
      open c_verifica_qtd_sequencia;
      fetch c_verifica_qtd_sequencia into vverifica_qtd_sequencia;
      close c_verifica_qtd_sequencia;
      --
      vhora_fim := phorario_inicio + (pintervalo_atendimento/24/60/60);
      --
      vid_agenda_urgente := peritoagendadetalhe_seq.nextval;
      --
      insert into peritoagendadetalhe 
             (codperitoagendadetalhe
             ,codperitoagenda
             ,codperitoagendadatastrancadas
             ,horinicio
             ,horfim
             ,indreservado
             ,indencaixe
             ,indativo
             ,datoperacao
             ,codusuariooperacao) 
      values (vid_agenda_urgente
             ,null
             ,null
             ,phorario_inicio
             ,vhora_fim --pegar phorario_agendamento + intervalo
             ,'Y'
             ,'Y'
             ,'N'
             ,sysdate
             ,nvl(v('GLOBAL_ID_USUARIO'),1));
      --
      if vverifica_qtd_sequencia > 1 then
		--
        for r_verifica_sequencia in c_pericia_agendamento_sequencia 
        loop
          --
          delete periciaagendamento pa
          where pa.id_periciaagendamento = r_verifica_sequencia.id_periciaagendamento;
          --
		  insert into periciaagendamento
				 (codperito
				 ,horchegada
				 ,codprontuariopericialoficio
				 ,codperitoagendadetalhe
				 ,codespecialidadenatureza
				 ,indreupreso
				 ,indativo
				 ,codpessoaacompanhante
				 ,numdocumentoacompanhante
				 ,datoperacao
				 ,codusuariooperacao
				 ,indefetivocadastrado
				 ,situacaoperito
				 ,situacao
				 ,tipo
				 ,situacaopericiando
				 ,perito_remanejado
				 ,peritoagendadetalhe_remanejado
         ,peticionamento)
		  values (pperito_remanejar
				 ,null -- É atualizado somente quando o perito comparecer
				 ,r_verifica_sequencia.codprontuariopericialoficio
				 ,vid_agenda_urgente
				 ,vdados_perito_remanejar.codespecialidadenatureza
				 ,r_verifica_sequencia.indreupreso
				 ,r_verifica_sequencia.indativo
				 ,r_verifica_sequencia.codpessoaacompanhante
				 ,r_verifica_sequencia.numdocumentoacompanhante
				 ,sysdate
				 ,nvl(v('GLOBAL_ID_USUARIO'),1)
				 ,vdados_perito_remanejar.efetivo_cadastrado
				 ,vdados_perito_remanejar.situacao
				 ,'AGENDADA/AGUARDANDO'
				 ,r_verifica_sequencia.tipo
				 ,r_verifica_sequencia.situacaopericiando
				 ,r_verifica_sequencia.codperito
				 ,pperito_agenda_detalhe
         ,'PENDENTE');
          --
          open cperitoagenda(pperito_agenda_detalhe);
      	  fetch cperitoagenda into vperitoagenda;
      	  close cperitoagenda;
          --
          open cperitoagenda(vid_agenda_urgente);
      	  fetch cperitoagenda into vperitoagenda_nova;
      	  close cperitoagenda;
          --
          if nvl(r_verifica_sequencia.tipo, 'P') = 'P' then
			--
			update peritoagenda pa
			   set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes + 1)
			 where pa.codperitoagenda = vperitoagenda.codperitoagenda;
			--
			update peritoagenda pa
			   set pa.qtdpericiasrestantes = (vperitoagenda_nova.qtdpericiasrestantes - 1)
			 where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
			--
		  elsif nvl(r_verifica_sequencia.tipo, 'P') = 'A' then
			--
			update peritoagenda pa
			   set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes + 1)
			 where pa.codperitoagenda = vperitoagenda.codperitoagenda;
			--
			update peritoagenda pa
			   set pa.qtdavaliacoesrestantes = (vperitoagenda_nova.qtdavaliacoesrestantes - 1)
			 where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
			--
		  end if;
          --
        end loop;
        -- COMENTADO POIS O HORARIO JA É CRIADO RESERVADO
        /*update peritoagendadetalhe pad
        set pad.indreservado = 'Y'
        where pad.codperitoagendadetalhe = vid_agenda_urgente;*/
        -- VERIFICAR (SE O ANTIGO HORARIO ESTA SENDO REMANEJADO, ELE VOLTA A SER NAO RESERVADO PARA SER UTILIZADO???)
        update peritoagendadetalhe pad
        set pad.indreservado = 'N'
        where pad.codperitoagendadetalhe = pperito_agenda_detalhe;
        --
      else
        --
        open c_dados_agendamento_remanejado;
        fetch c_dados_agendamento_remanejado into vdados_agendamento_remanejado;
        close c_dados_agendamento_remanejado;
        --
		insert into periciaagendamento
			   (codperito
			   ,horchegada
			   ,codprontuariopericialoficio
			   ,codperitoagendadetalhe
			   ,codespecialidadenatureza
			   ,indreupreso
			   ,indativo
			   ,codpessoaacompanhante
			   ,numdocumentoacompanhante
			   ,datoperacao
			   ,codusuariooperacao
			   ,indefetivocadastrado
			   ,situacaoperito
			   ,situacao
			   ,tipo
			   ,situacaopericiando
			   ,perito_remanejado
			   ,peritoagendadetalhe_remanejado
         ,peticionamento)
		values (pperito_remanejar
			   ,null -- É atualizado somente quando o perito comparecer
			   ,vdados_agendamento_remanejado.codprontuariopericialoficio
			   ,vid_agenda_urgente 
			   ,vdados_perito_remanejar.codespecialidadenatureza
			   ,vdados_agendamento_remanejado.indreupreso
			   ,vdados_agendamento_remanejado.indativo
			   ,vdados_agendamento_remanejado.codpessoaacompanhante
			   ,vdados_agendamento_remanejado.numdocumentoacompanhante
			   ,sysdate
			   ,nvl(v('GLOBAL_ID_USUARIO'),1)
			   ,vdados_perito_remanejar.efetivo_cadastrado
			   ,vdados_perito_remanejar.situacao
			   ,'AGENDADA/AGUARDANDO'
			   ,vdados_agendamento_remanejado.tipo
			   ,vdados_agendamento_remanejado.situacaopericiando
			   ,vdados_agendamento_remanejado.codperito
			   ,pperito_agenda_detalhe
         ,'PENDENTE');
        --
        open cperitoagenda(pperito_agenda_detalhe);
      	fetch cperitoagenda into vperitoagenda;
      	close cperitoagenda;
        --
        open cperitoagenda(vid_agenda_urgente);
      	fetch cperitoagenda into vperitoagenda_nova;
      	close cperitoagenda;
        --
        if nvl(vdados_agendamento_remanejado.tipo, 'P') = 'P' then
		  --
		  update peritoagenda pa
		  set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes + 1)
		  where pa.codperitoagenda = vperitoagenda.codperitoagenda;
		  --
		  update peritoagenda pa
		  set pa.qtdpericiasrestantes = (vperitoagenda_nova.qtdpericiasrestantes - 1)
		  where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
		  --
		elsif nvl(vdados_agendamento_remanejado.tipo, 'P') = 'A' then
		  --
		  update peritoagenda pa
		  set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes + 1)
		  where pa.codperitoagenda = vperitoagenda.codperitoagenda;
		  --
		  update peritoagenda pa
		  set pa.qtdavaliacoesrestantes = (vperitoagenda_nova.qtdavaliacoesrestantes - 1)
		  where pa.codperitoagenda = vperitoagenda_nova.codperitoagenda;
		  --
		end if;
        --
	  end if;
      --
      delete periciaagendamento pa
      where pa.id_periciaagendamento = ppericia_agendamento;
      -- COMENTADO POIS O HORARIO JA É CRIADO RESERVADO
      /*update peritoagendadetalhe pad
      set pad.indreservado = 'Y'
      where pad.codperitoagendadetalhe = vid_agenda_urgente;*/
      -- VERIFICAR (SE O ANTIGO HORARIO ESTA SENDO REMANEJADO, ELE VOLTA A SER NAO RESERVADO PARA SER UTILIZADO???)
      update peritoagendadetalhe pad
      set pad.indreservado = 'N'
      where pad.codperitoagendadetalhe = pperito_agenda_detalhe;
      --
      open c_datas(vid_agenda_urgente);
      fetch c_datas into vdatas;
      close c_datas;
      --
      /*if vdatas.data_antiga != vdatas.nova_data then
        --
        V_OFICIO := LAUDO_PKG_API_PDF.FNC_DADOS_PDF(''
                                                   ,vdados_processo_periciano.vnomePericiando
                                                   ,vdados_processo_periciano.venderecoPericia,vdados_processo_periciano.vnumeroprocesso
                                                   ,''
                                                   ,''
                                                   ,''
                                                   ,vdados_processo_periciano.vprontuario
                                                   ,''
                                                   ,''
                                                   ,''
                                                   ,vdados_processo_periciano.vvara
                                                   ,''
                                                   , to_char(vdatas.nova_data, 'DD/MM/YYYY') 
                                                   ,to_Char(vdatas.nova_data, 'HH24:SS')
                                                   ,''
                                                   ,''
                                                   ,''
                                                   ,'remanejamento'
                                                   ,''
                                                   ,''
                                                   ,'');
        --'cod 807 oficios de  agendamentos'
        LAUDO_PKG_SERVICO.prc_peticionamento(vdados_processo_periciano.vnumeroprocesso,V_OFICIO,'807');
        --                
      end if; */
      --
    end prc_remanejar_agenda_urgente;
    --
    procedure prc_agendar_psicologia(poficio                in number
                                    ,pprotocolo             in number
    			 		                      ,pperito                in number
    			 		                      ,pdatabase              in date
                                    ,pespecialidadenatureza in number
                                    ,pefetivocadastrado     in varchar2
                                    ,pseqagendamento        in number   default null
                                    ,ptipo_agendamento      in varchar2 default null
                                    ,praj                   in number
                                    ,pcdp                   in number   default null) is
      --  
      vprontuariopericial number;
      --
    begin  
      --  
      for r_reu in c_nome_reu(poficio) -- 
      loop
      --   raise_application_error(-20001,'oficio :'|| poficio || 'reu nome : ' || r_reu.nome);
        --
        open c_periciandos_reu(poficio   => poficio
                              ,pnome_reu => r_reu.nome);
        fetch c_periciandos_reu into vpericiandos_reu;   -- vpericiandos_reu veio vazio o  r_reu.nome que está sendo passado não está no oficiopericiando
        close c_periciandos_reu;
        --
        if vpericiandos_reu.situacaopericiando = 2 then
          --
          vreupreso := 'S';
          --
        else
          --
          vreupreso := 'N';
          --
        end if;
        --             
        open c_data_agendamento_reu(pespecialidadenatureza => pespecialidadenatureza,
                                    pdatabase              => pdatabase,
                                    praj                   => praj,
                                    pperito                => pperito,
                                    pcdp                   => pcdp );
        fetch c_data_agendamento_reu into vdata_agendamento_reu;
        close c_data_agendamento_reu;
        --
     
        select ppo.codprontuariopericialoficio into vprontuariopericial
        from prontuariopericialoficio ppo
        ,    prontuariopericial       pp
        where ppo.idprontuariopericial = pp.idprontuariopericial
          and ppo.idprotocolo          = pprotocolo
          and pp.codpericiando         = vpericiandos_reu.codpericiando;
        --
   
        update peritoagendadetalhe pad
        set pad.indreservado = 'Y'
        where pad.codperitoagendadetalhe = vdata_agendamento_reu.codperitoagendadetalhe;
        --
        insert into periciaAgendamento (codperito
                                       ,horchegada
                                       ,codprontuariopericialOficio
                                       ,codperitoagendadetalhe
                                       ,codespecialidadenatureza
                                       ,indreupreso
                                       ,indativo
                                       ,codpessoaacompanhante
                                       ,numdocumentoacompanhante
                                       ,datoperacao
                                       ,codusuariooperacao
                                       ,indefetivocadastrado
                                       ,situacao
                                       ,tipo
                                       ,seqagendamento
                                       ,tipopericia
                                       ,peticionamento)
                                values( pperito
                                       ,null--vdata_agendamento_reu.horinicio -- BASE + 7 dias 
                                       ,vprontuariopericial -- PRONTUARIO REU
                                       ,vdata_agendamento_reu.codperitoagendadetalhe -- OUTRA
                                       ,pespecialidadenatureza
                                       ,vreupreso
                                       ,'Y' 
                                       ,null
                                       ,null
                                       ,sysdate
                                       ,nvl(v('GLOBAL_ID_USUARIO'),1) 
                                       ,pefetivocadastrado
                                       ,'AGENDADA/AGUARDANDO'
                                       ,nvl(ptipo_agendamento,'P')
                                       ,pseqagendamento
                                       ,nvl(ptipo_agendamento,'P')
                                       ,'PENDENTE');
        -- 
        vid_pericia_agendamento := seq_periciaagendamento.currval;
        --
        insert into historico_pericia_agendamento(id_periciaagendamento
                                                 ,codperito
                                                 ,codprontuariopericialoficio
                                                 ,codperitoagendadetalhe
                                                 ,codespecialidadenatureza
                                                 ,codusuariooperacao
                                                 ,dataoperacao
                                                 ,indefetivocadastrado
                                                 ,indurgente
                                                 ,indativo)
                                         values (vid_pericia_agendamento
                                                ,pperito
                                                ,vprontuariopericial
                                                ,vdata_agendamento_reu.codperitoagendadetalhe
                                                ,pespecialidadenatureza
                                                ,nvl(v('GLOBAL_ID_USUARIO'),1)
                                                ,sysdate
                                                ,pefetivocadastrado
                                                ,'N'
                                                ,'Y'); 
        --
        open cperitoagenda(vdata_agendamento.codperitoagendadetalhe);
        fetch cperitoagenda into vperitoagenda;
        close cperitoagenda;
        --
        if nvl(ptipo_agendamento, 'P') = 'P' then
          --   
          update peritoagenda pa
          set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes -1)
          where pa.codperitoagenda = vperitoagenda.codperitoagenda;
          --          
        elsif nvl(ptipo_agendamento, 'P') = 'A' then
          --    
          update peritoagenda pa
          set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes -1)
          where pa.codperitoagenda = vperitoagenda.codperitoagenda;
          --  
        end if;
      --
      end loop;
      --
    end prc_agendar_psicologia;
  --  
  function fnc_retorna_protuario_oficio_reu (poficio in number ,pprotocolo in number) return varchar2 is
      
      vprontuariopericial number;
      vcount              number := 1;
      vprontuarios        varchar2(500);
      
    begin 
      
      for r_reu in c_nome_reu(poficio) loop
          --
          open c_periciandos_reu(poficio   => poficio
                                ,pnome_reu => r_reu.nome);
          fetch c_periciandos_reu into vpericiandos_reu;
          close c_periciandos_reu;
          --  
          
          select ppo.codprontuariopericialoficio into vprontuariopericial
            from prontuariopericialoficio ppo,
                 prontuariopericial pp
           where ppo.idprontuariopericial = pp.idprontuariopericial
             and ppo.idprotocolo          = pprotocolo
             and pp.codpericiando         = vpericiandos_reu.codpericiando;
             
          if vcount = 1 then
          --
            vprontuarios := vprontuariopericial;
            
            vcount := vcount + 1;
          --
          else  
          --
            vprontuarios := vprontuarios ||' , '|| vprontuariopericial;
            
            vcount := vcount + 1;
          --
          end if;
      end loop;
      
     return (vprontuarios); 
    
    end fnc_retorna_protuario_oficio_reu;
  --   
  function fnc_retorna_qtd_reu (poficio in number) return number is
      
      vqtd number := 0;
      
    begin 
    
     for r_reu in c_nome_reu(poficio) loop
      --
      open c_periciandos_reu(poficio   => poficio
                            ,pnome_reu => r_reu.nome);
      fetch c_periciandos_reu into vpericiandos_reu;
      --
      if c_periciandos_reu%found then
            --
            vqtd := vqtd + 1;
            --
      end if;
      
      close c_periciandos_reu;
 
     end loop;
 
     return (vqtd); 
    
    end fnc_retorna_qtd_reu;    
  --
  procedure prc_agendar_urgente(pespecialidade             in number
                               ,pnatureza                  in number
                               ,pcodperito                 in number
                               ,ptipo_agendamento          in varchar2
                               ,pdata_agendamento          in date
                               ,phorario_inicio            in date
                               ,phorario_fim               in date   default null
                               ,pintervalo_atendimento     in number default null
                               ,pprontuariopericialoficio  in number
                               ,preu                       in varchar2
                               --retorno
                               ,pidpericiaagendamento      out number) is 
    --
    vid_pericia_urgente number;
    --
    cursor c_especialidade_natureza is
      select en.codespecialidadenatureza
      from especialidadenatureza en
      where en.codespecialidade = pespecialidade
        and en.codnatureza 	    = pnatureza;
    vcod_especialidade_natureza number;
    --
    cursor c_situacao_perito is 
      select case 
               when p.indefetivo = 'Y' or  p.indcredenciado = 'Y' then 'Y'
               else 'N' 
             end efetivocadastrado
      from perito p
      where p.codperito = pcodperito;
    vsituacao_perito varchar2(1);
    --
    vhora_fim     date;
    vtipo_pericia varchar2(2);
    --
  begin
    --
    vid_pericia_urgente := peritoagendadetalhe_seq.nextval;
    --
    if phorario_fim is null then
      --
      vhora_fim     := phorario_inicio + (pintervalo_atendimento/24/60/60);
      vtipo_pericia := 'U'; 
      --
    else
      --
      vhora_fim     := phorario_inicio;
      vtipo_pericia := 'IS'; 
      --
    end if;
    --
    insert into peritoagendadetalhe 
           (codperitoagendadetalhe
           ,codperitoagenda
           ,codperitoagendadatastrancadas
           ,horinicio
           ,horfim
           ,indreservado
           ,indencaixe
           ,indativo
           ,datoperacao
           ,codusuariooperacao) 
    values (vid_pericia_urgente
           ,null
           ,null
           ,phorario_inicio
           ,vhora_fim --pegar phorario_agendamento + intervalo
           ,'Y'
           ,'Y'
           ,'N'
           ,sysdate
           ,nvl(v('GLOBAL_ID_USUARIO'),1));
    --
    open c_especialidade_natureza;
    fetch c_especialidade_natureza into vcod_especialidade_natureza;
    close c_especialidade_natureza;
    --
    open c_situacao_perito;
    fetch c_situacao_perito into vsituacao_perito;
    close c_situacao_perito;
    --
    if preu = 'Réu/Ré Preso(a)' then
        --
        vreupreso := 'S';
        --
      else
        --
        vreupreso := 'N';
        --
	  end if;    
    --
    insert into periciaAgendamento
		   (codperito
		   ,horchegada
		   ,codprontuariopericialOficio
		   ,codperitoagendadetalhe
		   ,codespecialidadenatureza
		   ,indreupreso
		   ,indativo
		   ,codpessoaacompanhante
		   ,numdocumentoacompanhante
		   ,datoperacao
		   ,codusuariooperacao
		   ,indefetivocadastrado
		   ,situacao
		   ,tipo
		   ,seqagendamento
       ,tipopericia
       ,peticionamento)
    values (pcodperito
		   ,null
		   ,pprontuariopericialoficio
		   ,vid_pericia_urgente
		   ,vcod_especialidade_natureza
		   ,vreupreso
		   ,'Y' 
		   ,null
		   ,null
		   ,sysdate
		   ,nvl(v('GLOBAL_ID_USUARIO'),1) 
		   ,vsituacao_perito
		   ,'AGENDADA/AGUARDANDO'
		   ,nvl(ptipo_agendamento,'P')
		   ,0
       ,vtipo_pericia
       ,'PENDENTE');
    --
    vid_pericia_agendamento := seq_periciaagendamento.currval;
    --
    insert into historico_pericia_agendamento
           (id_periciaagendamento
           ,codperito
           ,codprontuariopericialoficio
           ,codperitoagendadetalhe
           ,codespecialidadenatureza
           ,codusuariooperacao
           ,dataoperacao
           ,indefetivocadastrado
           ,indurgente
           ,indativo)
	values (vid_pericia_agendamento
	  	   ,pcodperito
	  	   ,pprontuariopericialoficio
	  	   ,vid_pericia_urgente
	  	   ,vcod_especialidade_natureza
	  	   ,nvl(v('GLOBAL_ID_USUARIO'),1) -- Integração
	  	   ,vdata_operacao
	  	   ,vsituacao_perito
	  	   ,'N'
	  	   ,'Y');
      --
      pidpericiaagendamento := vid_pericia_agendamento;
      --
  end prc_agendar_urgente;
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
                               ,pidpericiaagendamento     out number) is
    --
    cursor c_perito_agendamento(pespecialidade in number      
							   ,pnatureza	   in number      
      						   ,praj		   in number
                               ,pperito        in number) is  
	  select pt.codperito
	  ,	   	 p.nompessoa
	  ,	   	 en.codespecialidadenatureza
      ,      case 
               when pt.indefetivo = 'Y' or  pt.indcredenciado = 'Y' then 'Y'
               else 'N' 
             end efetivocadastrado
	  from perito 			           pt
	  ,	   pessoaimesc 		 		   pi
	  ,	   pessoa		 		 	   p
	  ,    peritoespecialidade 		   pe
	  ,    peritoespecialidadenatureza pen
	  ,    especialidade			   e
	  ,    natureza				       n
	  ,	   especialidadenatureza       en
	  ,	   peritoperfil				   pp
      ,    peritogeracaoagenda         pga
      ,    peritoagenda                pa
      ,    peritoagendadetalhe         pad
	  where pt.codpessoaimesc           = pi.codpessoaimesc
      and pt.indativo                 = 'Y'
	  	and pi.situacaopessoaimesc      = 'Y'
	  	and p.codpessoa      	          = pi.codpessoa
	  	and pe.codperito		            = pt.codperito
      and pt.codperito                = pperito
	  	and pe.indativo		              = 'Y'
	  	and pe.codperitoespecialidade   = pen.codperitoespecialidade
	  	and e.codespecialidade 		      = pe.codespecialidade
	  	and en.codespecialidadenatureza = pen.codespecialidadenatureza
	  	and en.indativo				          = 'Y'
		and en.codnatureza			          = n.codnatureza
		and n.codnatureza			           	= pnatureza
		and e.codespecialidade		        = pespecialidade
	    and pp.codperito  			       	= pt.codperito
        and pga.codperitoperfil         = pp.codperitoperfil
        and pga.codperito               = pp.codperito
        and pga.codperitogeracaoagenda  = pa.codperitogeracaoagenda
        and pa.codperitoagenda          = pad.codperitoagenda
        and pa.datatendimento           = trunc(pad.horinicio)
        and pad.indreservado            = 'N'
        and pad.indencaixe              = 'N'
        and pad.indativo                = 'Y'
        --and pad.horinicio               > sysdate !!!!
        and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))     
	    and ((pp.codraj	= praj
	          and praj is not null)
	     or (praj is null ))
        order by pt.indefetivo desc, pt.indcredenciado desc, pt.indcadastrado desc;
	v_perito_agendamento c_perito_agendamento%rowtype;
    --
    cursor c_oficio_protocolo is 
      select p.id_oficio 
      ,      o.nomelocalprisao
      from protocolo p
      ,    oficio    o
      where p.id_protocolo = pprotocolo
        and p.id_oficio    = o.id_oficio;
    voficio          number;
    vnomelocalprisao varchar2(120);
    --
  begin
    --
    open c_perito_agendamento(pespecialidade, pnatureza,praj_definida, pcodperito);
    fetch c_perito_agendamento into v_perito_agendamento;
    close c_perito_agendamento;
    --
    open c_data_agendamento(pespecialidadenatureza => v_perito_agendamento.codespecialidadenatureza
                           ,pperito                => v_perito_agendamento.codperito
                           ,praj                   => praj_definida);
    fetch c_data_agendamento into vdata_agendamento;
    if c_data_agendamento%found then
      --
      vdata_agendamento_prontuario := trunc(vdata_agendamento.horinicio);
      --
      vdata_operacao := sysdate;
      --
      vid_pericia_agendamento := seq_periciaagendamento.nextval;
      --
      if preu = 'Réu/Ré Preso(a)' then
        --
        vreupreso := 'S';
        --
      else
        --
        vreupreso := 'N';
        --
	    end if; 
      --
      insert into periciaAgendamento
    	       (id_periciaagendamento
               ,codperito
    		   ,horchegada
    		   ,codprontuariopericialOficio
    		   ,codperitoagendadetalhe
    		   ,codespecialidadenatureza
    	       ,indreupreso
    		   ,indativo
    		   ,codpessoaacompanhante
    		   ,numdocumentoacompanhante
    		   ,datoperacao
    		   ,codusuariooperacao
    		   ,indefetivocadastrado
    		   ,situacao
    		   ,tipo
    		   ,seqagendamento
           ,tipopericia
           ,peticionamento)
    	values (vid_pericia_agendamento
               ,v_perito_agendamento.codperito
    		   ,null--vdata_agendamento.horinicio
    		   ,pprontuariopericialoficio
    		   ,vdata_agendamento.codperitoagendadetalhe
    		   ,v_perito_agendamento.codespecialidadenatureza
    		   ,vreupreso
    		   ,'Y' -- Agendamento sempre entra como ativo
    		   ,null
    		   ,null
    		   ,vdata_operacao
    		   ,nvl(v('GLOBAL_ID_USUARIO'),1) 
    		   ,v_perito_agendamento.efetivocadastrado
    	       ,'AGENDADA/AGUARDANDO'
    		   ,nvl(ptipo_agendamento,'P')
    		   ,0
           ,'E'
           ,'PENDENTE');
      --
      update peritoagendadetalhe pad
      set pad.indreservado = 'Y'
      where pad.codperitoagendadetalhe = vdata_agendamento.codperitoagendadetalhe;
      --
      insert into historico_pericia_agendamento
        	   (id_periciaagendamento
        	   ,codperito
        	   ,codprontuariopericialoficio
        	   ,codperitoagendadetalhe
        	   ,codespecialidadenatureza
        	   ,codusuariooperacao
        	   ,dataoperacao
        	   ,indefetivocadastrado
        	   ,indurgente
        	   ,indativo)
        values (vid_pericia_agendamento
      		   ,v_perito_agendamento.codperito
      		   ,pprontuariopericialoficio
      		   ,vdata_agendamento.codperitoagendadetalhe
      		   ,v_perito_agendamento.codespecialidadenatureza
      		   ,nvl(v('GLOBAL_ID_USUARIO'),1) -- Integração
      		   ,vdata_operacao
      		   ,v_perito_agendamento.efetivocadastrado
      		   ,'N'
      		   ,'Y');
      --
      laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => pprotocolo
  										 			   ,pstatus    => 'AGENDADO');
      --
      open c_oficio_protocolo;
      fetch c_oficio_protocolo into voficio, vnomelocalprisao;
      close c_oficio_protocolo;
      --
      update prontuariopericialoficio ppo
	  set ppo.dataagendamento = vdata_agendamento_prontuario
	  where ppo.id_oficio = voficio;
      --
      open c_perito_agenda_agendamento(vdata_agendamento.codperitoagendadetalhe); --verificar não há certeza se varios pad são para 1 peritoagenda
      fetch c_perito_agenda_agendamento into vcodperitoagenda;
      close c_perito_agenda_agendamento;
      --
      open c_verifica_agenda_completa(vcodperitoagenda);
      fetch c_verifica_agenda_completa into vverifica;
      if c_verifica_agenda_completa%notfound then
        --
        open c_define_rotina_portaria(pprontuariopericialoficio);
        fetch c_define_rotina_portaria into vlocal_pericia;
        close c_define_rotina_portaria;
        --
        open c_data_agenda_completa(vcodperitoagenda);
        fetch c_data_agenda_completa into vdata;
        close c_data_agenda_completa;
        --
        if vlocal_pericia = 2 then -- CAPITAL
          --
          if vnomelocalprisao is not null then
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          else
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_capital_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        elsif vlocal_pericia = 3 then -- RAJ
          --
          if vnomelocalprisao is not null then
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          else
            --
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_raj_completa(v_perito_agendamento.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        end if;
        --
      end if;
      close c_verifica_agenda_completa;
      --
    end if;
    close c_data_agendamento;
    --
    pidpericiaagendamento := vid_pericia_agendamento;
    --
  end prc_agendar_externa;
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
                                ,pqtpericiando             out number) is
 
vqtdpericiando      number := pqtdpericiando;
vverifica           number;
vdata_operacao      date;
vqtd_reu            number:= 0;
vexists             varchar2(1);
vraj                number;
pseq_maior          number;
verro               varchar2(20) := 'N';
vretorno            varchar2(100);
erro_tratado        exception;
vprontuariopericial number;
vseq_maior          number:=0;
 
 cursor c_valida_prontuario is
 select ppo.codprontuariopericialoficio
   from prontuariopericialoficio ppo
  where ppo.idprotocolo = pprotocolo;
 
cursor c_prontuario_pericial(pseq_maior in number) is
select ppo.codprontuariopericialoficio
  from prontuariopericialoficio ppo
 where ppo.idprotocolo = pprotocolo
   and ppo.id_oficio   = poficio
   and not exists (select 1
                     from periciaAgendamento pa
                     where pa.codprontuariopericialOficio = ppo.codprontuariopericialoficio
            			    and pa.seqagendamento               = pseq_maior);
 
cursor cagendamento is 
 select max(pa.id_periciaagendamento)
   ,    trunc(pad.horinicio) data_agendada
   ,    pa.codperito
   ,    o.id_oficio
   from periciaagendamento       pa
   ,    peritoagendadetalhe      pad
   ,    prontuariopericialoficio ppo
   ,    oficio                   o
   ,    especialidadenatureza    en
  where pa.codperitoagendadetalhe      = pad.codperitoagendadetalhe
    and pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
    and ppo.id_oficio                  = o.id_oficio
    and pa.codespecialidadenatureza    = en.codespecialidadenatureza
    and en.codespecialidade            = pespecialidade
    and en.codnatureza                 = pnatureza
    and o.numeroprocesso               = (select o2.numeroprocesso
                                            from oficio o2
                                           where o2.id_oficio = poficio)
  group by pad.horinicio,pa.codperito,o.id_oficio;
  --
	vagendamento cagendamento%rowtype;
  --
 cursor c_verifica_agenda(pdata_base_periciando in date,
                          pperito               in number,
                          pqtdpericiando        in number,
                          praj                  in number) is 
  select 1 
    from especialidadenatureza       en
    ,    peritoespecialidadenatureza pen
    ,    peritoperfil                pp
    ,    peritogeracaoagenda         pga
    ,    peritoagenda                pa
    ,    peritoagendadetalhe         pad
    ,    perito                      pt
   where pp.codperito                       = pt.codperito
     and pt.indativo                        = 'Y' 
     and pa.qtdpericiasrestantes            >= vqtdpericiando
     and en.codespecialidade                = pespecialidade
     and en.codnatureza                     = pnatureza 
     and en.codespecialidadenatureza        = pen.codespecialidadenatureza
     and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
     and pga.codperitoperfil                = pp.codperitoperfil
     and pga.codperito                      = pp.codperito
     and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
     and pa.codperitoagenda                 = pad.codperitoagenda
     and pa.datatendimento                  = trunc(pad.horinicio)
     and pad.indreservado                   = 'N'
     and pad.indencaixe                     = 'N'
     and pad.indativo                       = 'Y'
     and pp.codperito                       = pperito
     and pp.codraj                          = praj
     and pcdp                               is null
     and trunc(pad.horinicio)               >= trunc(pdata_base_periciando) + 7
     and ((pa.qtdpericiasrestantes >= vqtdpericiando and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes >= vqtdpericiando and ptipo_agendamento = 'A'))
     and not exists (select 1
                       from rajdianaotrabalhado rnt
                      where rnt.codraj              = pp.codraj
                        and rnt.datdianaotrabalhado = trunc(pad.horinicio))
     and pad.codperitoagendadatastrancadas is null
     union
     select 1 
       from especialidadenatureza       en
       ,    peritoespecialidadenatureza pen
       ,    peritoperfil                pp
       ,    peritogeracaoagenda         pga
       ,    peritoagenda                pa
       ,    peritoagendadetalhe         pad
       ,    perito                      pt
      where pp.codperito                       = pt.codperito
        and pt.indativo                        = 'Y'  
        and pa.qtdpericiasrestantes            >= vqtdpericiando
        and en.codespecialidade                = pespecialidade
        and en.codnatureza                     = pnatureza 
        and en.codespecialidadenatureza        = pen.codespecialidadenatureza
        and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
        and pga.codperitoperfil                = pp.codperitoperfil
        and pga.codperito                      = pp.codperito
        and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
        and pa.codperitoagenda                 = pad.codperitoagenda
        and pa.datatendimento                  = trunc(pad.horinicio)
        and pad.indreservado                   = 'N'
        and pad.indencaixe                     = 'N'
        and pad.indativo                       = 'Y'
        and pp.codperito                       = pperito
        and pp.codcpd                          = pcdp
        and pcdp                                is not null
        and trunc(pad.horinicio)              >= trunc(pdata_base_periciando) + 7
        and ((pa.qtdpericiasrestantes >= vqtdpericiando and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes >= vqtdpericiando and ptipo_agendamento = 'A'))
        and not exists (select 1
                          from rajdianaotrabalhado rnt
                         where rnt.codraj              = pp.codraj
                           and rnt.datdianaotrabalhado = trunc(pad.horinicio))
        and pad.codperitoagendadatastrancadas is null;
 
begin    
 
    for r_reu in c_nome_reu(poficio) loop
      --
      open c_periciandos_reu(poficio   => poficio
                            ,pnome_reu => r_reu.nome);
      fetch c_periciandos_reu into vpericiandos_reu;
        --
        if c_periciandos_reu%found then
              --
              vqtd_reu := vqtd_reu + 1;
              --
        end if;
        --
      close c_periciandos_reu; 
      --
      end loop;
      
   if pqtdpericiando > 1 and vqtd_reu > 1 then
     --
     pvalida     := 'S';
     ppsicologia := 'S';
     --
   else
     --
     open cagendamento;
     fetch cagendamento into vagendamento;
     if cagendamento%notfound then
       --
       pvalida     := 'S';
       ppsicologia := 'N';
       --
       if pqtdpericiando = 0 then
          --
          vqtdpericiando := vqtd_reu;
          --
       end if;
     --
     else  
     --
       pvalida     := 'N';
       ppsicologia := 'N';
       --
       if pqtdpericiando = 0 then
          --
          vqtdpericiando := vqtd_reu;
          --
       end if;
       --
       open c_dados_oficio(poficio);
       fetch c_dados_oficio into vdados_oficio;
       close c_dados_oficio;
       --
       if vdados_oficio.localpericia = 2 then
          
          vraj := 1;
        
       else 
          
          vraj := laudo_pkg_agendamento.fnc_define_raj(pdescentralizada => vdados_oficio.descentralizada
                                                      ,praj             => vdados_oficio.raj
                                                      ,pcomarca         => vdados_oficio.comarcaprocesso);
       end if; 
                 
       
        open c_verifica_agenda(pdata_base_periciando => vagendamento.data_agendada ,
                               pperito               => vagendamento.codperito,
                               pqtdpericiando        => vqtdpericiando,
                               praj                  => vraj);
        fetch c_verifica_agenda into vverifica;
        if c_verifica_agenda%notfound then
          --
          verro    := 'S';
          vretorno := 'Agendamento de psicologia não realizado, agenda não disponível!';
          raise erro_tratado;
          --
        else 
          
        if vdados_oficio.situacaopericiando = 2 then
          --
          vreupreso := 'S';
          --
        else
          --
          vreupreso := 'N';
          --
	       end if;   
         
      for r_valida_prontuario in c_valida_prontuario
      loop
      --
      open c_seq_prontuario_pericial_oficio(r_valida_prontuario.codprontuariopericialoficio);
      fetch c_seq_prontuario_pericial_oficio into vseq_prontuario_pericial_oficio;
        close c_seq_prontuario_pericial_oficio;
          --
          if nvl(vseq_prontuario_pericial_oficio,0) > vseq_maior then
        --
        vseq_maior := vseq_prontuario_pericial_oficio;
            --
      end if;
          --
      end loop;     
        
        for r_agenda_sequencia in (select pad.codperitoagendadetalhe
                                   ,      pad.horinicio
                                   ,	    pad.horfim
                                   ,      en.codespecialidadenatureza
                                   ,      case 
                                          when pt.indefetivo = 'Y' or pt.indcredenciado = 'Y' then 'Y'
                                          else 'N' 
                                          end efetivocadastrado
                                     from peritoagenda                pa
                                   ,      peritoagendadetalhe         pad
                                   ,      peritogeracaoagenda         pga
                                   ,      peritoperfil                pp
                                   ,      peritoespecialidadenatureza pen
                                   ,      perito                      pt
                                   ,      especialidadenatureza       en
                                    where pp.codperito                       = pt.codperito
                                      and pt.indativo                        = 'Y' 
                                      and pa.codperitoagenda                 = pad.codperitoagenda
                                      and pa.qtdpericiasrestantes            >= vqtdpericiando
                                      and pa.datatendimento                  = trunc(pad.horinicio)
                                      and pad.indreservado 	                 = 'N'
                                      and pad.indencaixe	 	                 = 'N'
                                      and pad.INDATIVO 		                   = 'Y'
                                      and trunc(pad.horinicio)               >= trunc(vagendamento.data_agendada) + 7
                                      --and pad.HORINICIO					             > sysdate !!!!
                                      and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                                         and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                                      or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                                          and pad.HORINICIO > sysdate))
                                      and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
                                      and pga.codperito                      = vagendamento.codperito
                                      and pga.codperitoperfil                = pp.codperitoperfil
                                      and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
                                      and pen.codespecialidadenatureza       = en.codespecialidadenatureza
                                      and en.codespecialidade                = pespecialidade
                                      and en.codnatureza                     = pnatureza
                                      and pp.codraj                          = vraj
                                      and pcdp                               is null
                                      union 
                                      select pad.codperitoagendadetalhe
                                   ,      pad.horinicio
                                   ,	    pad.horfim
                                   ,      en.codespecialidadenatureza
                                   ,      case 
                                          when pt.indefetivo = 'Y' or pt.indcredenciado = 'Y' then 'Y'
                                          else 'N' 
                                          end efetivocadastrado
                                     from peritoagenda                pa
                                   ,      peritoagendadetalhe         pad
                                   ,      peritogeracaoagenda         pga
                                   ,      peritoperfil                pp
                                   ,      peritoespecialidadenatureza pen
                                   ,      perito                      pt
                                   ,      especialidadenatureza       en
                                    where pp.codperito                       = pt.codperito
                                      and pt.indativo                        = 'Y' 
                                      and pa.codperitoagenda                 = pad.codperitoagenda
                                      and pa.qtdpericiasrestantes            >= vqtdpericiando
                                      and pa.datatendimento                  = trunc(pad.horinicio)
                                      and pad.indreservado 	                 = 'N'
                                      and pad.indencaixe	 	                 = 'N'
                                      and pad.INDATIVO 		                   = 'Y'
                                      and trunc(pad.horinicio)               >= trunc(vagendamento.data_agendada) + 7
                                      --and pad.HORINICIO					             > sysdate !!!!
                                      and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                                         and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                                      or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                                          and pad.HORINICIO > sysdate))
                                      and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
                                      and pga.codperito                      = vagendamento.codperito
                                      and pga.codperitoperfil                = pp.codperitoperfil
                                      and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
                                      and pen.codespecialidadenatureza       = en.codespecialidadenatureza
                                      and en.codespecialidade                = pespecialidade
                                      and en.codnatureza                     = pnatureza
                                      and pp.codcpd                          = pcdp
                                      and pcdp                               is not null
                                     order by 2 asc
                                   fetch first vqtdpericiando rows only) loop
  
            vdata_operacao				 := sysdate;
            --
            update peritoagendadetalhe pad
            set pad.indreservado = 'Y'
            where pad.codperitoagendadetalhe = r_agenda_sequencia.codperitoagendadetalhe;
            --
                vprontuariopericial := null;
            --
            open  c_prontuario_pericial(vseq_maior);
            fetch c_prontuario_pericial into vprontuariopericial;
            close c_prontuario_pericial;
            --
                insert into periciaAgendamento
                 (codperito
                 ,horchegada
                 ,codprontuariopericialOficio
                 ,codperitoagendadetalhe
                 ,codespecialidadenatureza
                 ,indreupreso
                 ,indativo
                 ,codpessoaacompanhante
                 ,numdocumentoacompanhante
                 ,datoperacao
                 ,codusuariooperacao
                 ,indefetivocadastrado
                 ,situacao
                 ,tipo
                 ,seqagendamento
                 ,tipopericia
                 ,peticionamento)
            values (vagendamento.codperito
                 ,null--r_agenda_sequencia.horinicio
                 ,vprontuariopericial
                 ,r_agenda_sequencia.codperitoagendadetalhe
                 ,r_agenda_sequencia.codespecialidadenatureza
                 ,vreupreso
                 ,'Y'
                 ,null
                 ,null
                 ,vdata_operacao
                 ,nvl(v('GLOBAL_ID_USUARIO'),1)  -- Integração
                 ,r_agenda_sequencia.efetivocadastrado
                 ,'AGENDADA/AGUARDANDO'
                 ,nvl(ptipo_agendamento,'P')
                 ,vseq_maior
                 ,nvl(ptipo_agendamento,'P')
                 ,'PENDENTE');
            --
            vid_pericia_agendamento := seq_periciaagendamento.currval;
            pidpericiaagendamento   := vid_pericia_agendamento;
            --
                insert into historico_pericia_agendamento
                 (id_periciaagendamento
                 ,codperito
                 ,codprontuariopericialoficio
                 ,codperitoagendadetalhe
                 ,codespecialidadenatureza
                 ,codusuariooperacao
                 ,dataoperacao
                 ,indefetivocadastrado
                 ,indurgente
                 ,indativo)
            values (vid_pericia_agendamento
                 ,vagendamento.codperito
                 ,vprontuariopericial
                 ,r_agenda_sequencia.codperitoagendadetalhe
                 ,r_agenda_sequencia.codespecialidadenatureza
                 ,1
                 ,vdata_operacao
                 ,r_agenda_sequencia.efetivocadastrado
                 ,'N'
                 ,'Y'); 
                --
                open cperitoagenda(r_agenda_sequencia.codperitoagendadetalhe);--vdata_agendamento.codperitoagendadetalhe);
                fetch cperitoagenda into vperitoagenda;
                close cperitoagenda;
         
                if nvl(ptipo_agendamento, 'P') = 'P' then
                --   
                  update peritoagenda pa
                     set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes -1)
                   where pa.codperitoagenda = vperitoagenda.codperitoagenda;
                --          
                elsif nvl(ptipo_agendamento, 'P') = 'A' then
                --    
                  update peritoagenda pa
                     set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes -1)
                   where pa.codperitoagenda = vperitoagenda.codperitoagenda;
                --  
                end if;
                --
        end loop;
        
        end if;
        
        close c_verifica_agenda;
     -- 
     end if;
     --
     close cagendamento;
     --
   end if;
   
  pqtpericiando := vqtdpericiando; 
  perro         := verro;

   -- log do agendamento --   
  insert into LOG_AGENDAMENTO(  PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 poficio,
                                 ptipo_agendamento,
                                 pqtdpericiando,
                                 pcdp,
                                 pprotocolo,
                                 perro ||' '|| vretorno,
                                 ppsicologia,
                                 pvalida, 
                                 pidpericiaagendamento,
                                 pqtpericiando, 
                                 vraj, 
                                 vreupreso,
                                '', 
                                 vprontuariopericial,
                                '',
                                'prc_valida_psicologia',
                                sysdate);

 
    exception
    when erro_tratado then
     perro := verro;
     insert into LOG_AGENDAMENTO(  PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 poficio,
                                 ptipo_agendamento,
                                 pqtdpericiando,
                                 pcdp,
                                 pprotocolo,
                                 perro ||' '|| vretorno,
                                 ppsicologia,
                                 pvalida, 
                                 pidpericiaagendamento,
                                 pqtpericiando, 
                                 vraj, 
                                 vreupreso,
                                 '', 
                                 vprontuariopericial,
                                 '',
                                 'prc_valida_psicologia',
                                 sysdate);
    when others then
     insert into LOG_AGENDAMENTO(  PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 poficio,
                                 ptipo_agendamento,
                                 pqtdpericiando,
                                 pcdp,
                                 pprotocolo,
                                 perro ||' '|| vretorno,
                                 ppsicologia,
                                 pvalida, 
                                 pidpericiaagendamento,
                                 pqtpericiando, 
                                 vraj, 
                                 vreupreso,
                                 '', 
                                 vprontuariopericial,
                                 '',
                                 'prc_valida_psicologia',
                                 sysdate);
                               
  end prc_valida_psicologia;
  --
  procedure prc_declaracao_comparecimento(pidprontuariopericial   in number default null
                                         ,ptipo_declaracao        in varchar2 default null
                                         ,pcod_periciando         in number default null
                                         ,pnumero_processo        in varchar2 default null
                                         ,passistente_selecionado in varchar2 default null
                                         ,pnome_acompanhante      in varchar2 default null
                                         ,pdocumento_acompanhante in varchar2 default null
                                         ,pperiodo_inicial        in varchar2 default null) is 
    --
    vres  clob;
    vbody clob;
    --
    cursor c_documento_periciando is 
      select (select sgltipodocumentoidentificacao
              from tipodocumentoidentificacao
              where codtipodocumentoidentificacao = col.c001) tipo
      ,	     col.c002 numero
      from apex_collections col
      where col.collection_name = 'COLL_DOCUMENTO_PERICIANDO'
        and col.c006            = 'Y'
      union
      select (select sgltipodocumentoidentificacao
              from tipodocumentoidentificacao
              where codtipodocumentoidentificacao = pd.tipo) tipo
      ,		 pd.numero numero
      from periciandodocumento pd
      where pd.codpericiando = pcod_periciando
        and pd.indprincipal  = 'Y';
    vtipo             varchar2(20);
    vnumero_documento varchar2(50);
    --
    cursor c_nome_periciando is 
      select vp.nome_periciando
      from laudo_vw_periciando vp 
      where vp.codpericiando = pcod_periciando;
    vnome_periciando varchar2(100);
    --
    cursor c_dados_assistente_tecnico(pcod_assistente_tecnico in number) is 
      select lat.nome
      ,	     lat.documento
      from assistentetecnico lat
      where lat.codassistentetecnico = pcod_assistente_tecnico;
    vnome_assistente_tecnico      varchar2(100);
    vdocumento_assistente_tecnico varchar2(30);
    --
    cursor c_comarca is 
      select dep.desc_comarca
      ,	     dep.desc_vara
      from prontuariopericialoficio 	   ppo
      ,	   oficio 			      		   o
      ,	   depara_raj_comarca_foro_vara_muni dep
      where ppo.idprontuariopericial = pidprontuariopericial
        and ppo.numprocesso		     = pnumero_processo
        and ppo.id_oficio 		     = o.id_oficio
        and o.foro				     = dep.cod_foro
        and o.raj				     = dep.cod_raj
        and o.vara				     = dep.cod_vara;
    vvara    varchar2(100);
    vcomarca varchar2(100);
    --
  begin 
    --
    if not apex_collection.collection_exists(p_collection_name => 'COL_DECLARACAO_COMPARECIMENTO') then
      --
      apex_collection.create_collection( p_collection_name => 'COL_DECLARACAO_COMPARECIMENTO');
      --
    else
      --  
      apex_collection.truncate_collection(p_collection_name =>'COL_DECLARACAO_COMPARECIMENTO');
      --
    end if;
    --
    open c_documento_periciando;
    fetch c_documento_periciando into vtipo, vnumero_documento;
    close c_documento_periciando;
    --
    open c_nome_periciando;
    fetch c_nome_periciando into vnome_periciando;
    close c_nome_periciando;
    --
    open c_comarca;
    fetch c_comarca into vcomarca, vvara;
    close c_comarca;
    --   
    apex_json.initialize_clob_output;
    --
    if ptipo_declaracao like 'P' then
      --
      apex_json.open_object;
      apex_json.write('nomeFicha', 'Ficha_declaracao_de_comparecimento_periciando', TRUE);
      apex_json.write('nomePericiando', vnome_periciando, TRUE);
      apex_json.write('numeroProcesso',pnumero_processo, TRUE);
      apex_json.write('documento', vtipo||':'||vnumero_documento, TRUE);
      apex_json.write('vara_comarca', vvara||' '||vcomarca, TRUE);
      apex_json.write('periodo', pperiodo_inicial||' às '||to_char(sysdate,'HH:MI'), TRUE);
      apex_json.write('data_comparecimento', to_char(sysdate,'DD/MM/YYYY'), TRUE);
      apex_json.close_object;
      --
      vbody := apex_json.get_clob_output;
      --
      APEX_JSON.FREE_OUTPUT;
      --
      apex_web_service.g_request_headers(1).name  := 'content-type';
      apex_web_service.g_request_headers(1).value := 'application/json';
      --
      vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Fichas/GeracaoFichas'
	   									        ,p_http_method => 'PUT'
									          --,p_https_host  => 'imesclaudo.sp.gov.br/'
										        ,p_body        => vbody);
      --
      --INSERT INTO TESTEPABLO VALUES (vbody,'--'); 
      --commit;
      --
      if apex_web_service.g_status_code = 200 then
	    --
        apex_json.parse(vres);
        v_oficio  :=  vres;    
        v_oficio  := apex_json.get_clob (p_path => 'oficioBase64');
        --
        apex_collection.add_member(p_collection_name => 'COL_DECLARACAO_COMPARECIMENTO'
                                  ,p_clob001         => v_oficio); 
        --
      else 
        --
        apex_collection.truncate_collection(p_collection_name =>'COL_DECLARACAO_COMPARECIMENTO'); 
        --
      end if;
      --
    end if;
    --
    if ptipo_declaracao like 'AT' then
      --
      for i in (select trim(regexp_substr(passistente_selecionado, '[^:]+', 1, level)) assistente from dual connect by level <= regexp_count(passistente_selecionado, ':')+1)
      loop
        --
        apex_json.open_object;
        apex_json.write('nomeFicha', 'Ficha_declaracao_de_comparecimento_assistente_tecnico', TRUE);
        apex_json.write('nomePericiando', vnome_periciando, TRUE);
        apex_json.write('numeroProcesso',pnumero_processo, TRUE);
        apex_json.write('documento', '', TRUE);
        apex_json.write('vara_comarca', vvara||' '||vcomarca, TRUE);
        apex_json.write('periodo', pperiodo_inicial||' às '||to_char(sysdate,'HH:MI'), TRUE);
        apex_json.write('data_comparecimento', to_char(sysdate,'DD/MM/YYYY'), TRUE);
        --
        apex_json.open_array('relatorioFichaAssistenteTecnico');
        --
        open c_dados_assistente_tecnico(i.assistente);
        fetch c_dados_assistente_tecnico into vnome_assistente_tecnico, vdocumento_assistente_tecnico;
        close c_dados_assistente_tecnico;
        --
        apex_json.open_object;
        apex_json.write('nomeAssistente', vnome_assistente_tecnico, TRUE);
        apex_json.write('doc',vdocumento_assistente_tecnico, TRUE);
        apex_json.close_object;
        --
        apex_json.close_all;
        --
        vbody := apex_json.get_clob_output;
        -- 
        APEX_JSON.FREE_OUTPUT;
        --
        --INSERT INTO TESTEPABLO VALUES (vbody,'--'); 
        --commit;
        --
        apex_web_service.g_request_headers(1).name  := 'content-type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        --
        vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Fichas/GeracaoFichas'
	   									          ,p_http_method => 'PUT'
									            --,p_https_host  => 'imesclaudo.sp.gov.br/'
										          ,p_body        => vbody);
        --
        --INSERT INTO TESTEPABLO VALUES (vbody,'--'); 
        --commit;
        --
        if apex_web_service.g_status_code = 200 then
	      --
          apex_json.parse(vres);
          v_oficio  := vres;    
          v_oficio  := apex_json.get_clob (p_path => 'oficioBase64');
          --
          apex_collection.add_member(p_collection_name => 'COL_DECLARACAO_COMPARECIMENTO'
                                    ,p_clob001         => v_oficio); 
          --
        else 
          --
          apex_collection.truncate_collection(p_collection_name => 'COL_DECLARACAO_COMPARECIMENTO'); 
          --
        end if;
        --
      end loop;
      --
    end if;
    --
    if ptipo_declaracao like 'C' then 
      --
      apex_json.open_object;
      apex_json.write('nomeFicha', 'Ficha_declaracao_de_comparecimento_acompanhante', TRUE);
      apex_json.write('nomePericiando', vnome_periciando, TRUE);
      apex_json.write('numeroProcesso',pnumero_processo, TRUE);
      apex_json.write('documento', vtipo||':'||pdocumento_acompanhante, TRUE);
      apex_json.write('nome_acompanhante', pnome_acompanhante, TRUE);
      -- apex_json.write('documento_acompanhante', pdocumento_acompanhante, TRUE);
      apex_json.write('vara_comarca', vvara||' '||vcomarca, TRUE);
      apex_json.write('periodo', pperiodo_inicial||' às '||to_char(sysdate,'HH:MI'), TRUE);
      apex_json.write('data_comparecimento', to_char(sysdate,'DD/MM/YYYY'), TRUE);
      apex_json.close_all;
      --
      vbody := apex_json.get_clob_output;
      -- 
      APEX_JSON.FREE_OUTPUT;
      --
      apex_web_service.g_request_headers(1).name  := 'content-type';
      apex_web_service.g_request_headers(1).value := 'application/json';
      --
      vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Fichas/GeracaoFichas'
	   									        ,p_http_method => 'PUT'
									          --,p_https_host  => 'imesclaudo.sp.gov.br/'
										        ,p_body        => vbody);
      --
      if apex_web_service.g_status_code = 200 then
	    --
        apex_json.parse(vres);
        v_oficio  := vres;    
        v_oficio  := apex_json.get_clob (p_path => 'oficioBase64');
        --
        apex_collection.add_member(p_collection_name => 'COL_DECLARACAO_COMPARECIMENTO'
                                  ,p_clob001         => v_oficio); 
        --
      else 
        --
        apex_collection.truncate_collection(p_collection_name => 'COL_DECLARACAO_COMPARECIMENTO'); 
        --
      end if;
      --
    end if;
    --
  end prc_declaracao_comparecimento;
  --
  procedure prc_req_exames_complementares is 
  begin
    --
    null;
    --
  end prc_req_exames_complementares; 
  --
  procedure prc_termo_consentimento(pcod_periciando         in number default null
                                   ,pnome_acompanhante      in varchar2 default null
                                   ,pdocumento_acompanhante in varchar2 default null) is 
    --
    vres  clob;
    vbody clob;
    --
    cursor c_documento_periciando is 
      select (select sgltipodocumentoidentificacao
              from tipodocumentoidentificacao
              where codtipodocumentoidentificacao = col.c001) tipo
      ,	     col.c002 numero
      from apex_collections col
      where col.collection_name = 'COLL_DOCUMENTO_PERICIANDO'
        and col.c006            = 'Y'
      union
      select (select sgltipodocumentoidentificacao
              from tipodocumentoidentificacao
              where codtipodocumentoidentificacao = pd.tipo) tipo
      ,		 pd.numero numero
      from periciandodocumento pd
      where pd.codpericiando = pcod_periciando
        and pd.indprincipal  = 'Y';
    vtipo             varchar2(20);
    vnumero_documento varchar2(50);
    --
    cursor c_nome_periciando is 
      select vp.nome_periciando
      from laudo_vw_periciando vp 
      where vp.codpericiando = pcod_periciando;
    vnome_periciando varchar2(100);
    --
  begin
    --
    if not apex_collection.collection_exists(p_collection_name => 'COL_TERMO_CONSENTIMENTO') then
      --
      apex_collection.create_collection( p_collection_name => 'COL_TERMO_CONSENTIMENTO');
      --
    else
      --  
      apex_collection.truncate_collection(p_collection_name =>'COL_TERMO_CONSENTIMENTO');
      --
    end if;
    --
    open c_documento_periciando;
    fetch c_documento_periciando into vtipo, vnumero_documento;
    close c_documento_periciando;
    --
    open c_nome_periciando;
    fetch c_nome_periciando into vnome_periciando;
    close c_nome_periciando;
    --
    apex_json.initialize_clob_output;
    --
    apex_json.open_object;
    apex_json.write('nomeFicha', 'termo_consentimento', TRUE);
    apex_json.write('nomePericiando',  pnome_acompanhante, TRUE);
    apex_json.write('documento', vtipo||':'|| pdocumento_acompanhante, TRUE);
    apex_json.write('nome_acompanhante', vnome_periciando, TRUE);
    apex_json.write('documento_acompanhante', vnumero_documento, TRUE);
    apex_json.close_all;
    --
    vbody := apex_json.get_clob_output;
    -- 
    APEX_JSON.FREE_OUTPUT;
    --
    apex_web_service.g_request_headers(1).name  := 'content-type';
    apex_web_service.g_request_headers(1).value := 'application/json';
    --
    vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Fichas/GeracaoFichas'
	 									      ,p_http_method => 'PUT'
									        --,p_https_host  => 'imesclaudo.sp.gov.br/'
										      ,p_body        => vbody);
    --
    if apex_web_service.g_status_code = 200 then
	  --
      apex_json.parse(vres);
      v_oficio  := vres;    
      v_oficio  := apex_json.get_clob (p_path => 'oficioBase64');
      --
      apex_collection.add_member(p_collection_name => 'COL_TERMO_CONSENTIMENTO'
                                ,p_clob001         => v_oficio); 
      --
    else 
      --
      apex_collection.truncate_collection(p_collection_name => 'COL_TERMO_CONSENTIMENTO'); 
      --
    end if;
    --
  end prc_termo_consentimento; 
  --
  procedure prc_agendar_externa_zona(pespecialidade    in number
                                    ,ptipo_agendamento in varchar2
                                    ,pzona             in varchar2
                                    ,poficio           in number
                                    ,praj              in number
                                    ,pprotocolo        in number
                                    ,pqtd_periciando   in number
                                    --retorno
                                    ,pidpericiaagendamento     out number) is 
                                    
vqt                 number;
vperito             number;
vmenor              number;    
vcount              number := 0;
vseq_maior          number := 0;
vprontuariopericial number;
 
cursor c_valida_prontuario is
select ppo.codprontuariopericialoficio
  from prontuariopericialoficio ppo
 where ppo.idprotocolo = pprotocolo;
 
cursor c_prontuario_pericial(pseq_maior in number) is
select ppo.codprontuariopericialoficio
  from prontuariopericialoficio ppo
 where ppo.idprotocolo = pprotocolo
   and ppo.id_oficio   = poficio
   and not exists (select 1
                     from periciaAgendamento pa
                     where pa.codprontuariopericialOficio = ppo.codprontuariopericialoficio
                      and pa.seqagendamento               = pseq_maior);
 
cursor cperito is 
select  pt.codperito
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    peritogeracaoagenda         pga
        ,    peritoagenda                pa
        ,    peritoagendadetalhe         pad
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and pp.zona                           like ('%'||pzona||'%')
          --and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pga.codperitoperfil                = pp.codperitoperfil
          and pga.codperito                      = pp.codperito
          and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.datatendimento                  = trunc(pad.horinicio)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.indativo                       = 'Y'
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pp.codraj                          = praj
          and ((pa.qtdpericiasrestantes >= pqtd_periciando and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes >= pqtd_periciando and ptipo_agendamento = 'A'))
          and not exists (select 1
                          from rajdianaotrabalhado rnt
                          where rnt.codraj              = pp.codraj
                            and rnt.datdianaotrabalhado = trunc(pad.horinicio))
          and pad.codperitoagendadatastrancadas is null;
  --
  vperito_agenda_datalhe number;
  --
begin 
     
     for c1 in cperito loop
     -- para retornar qual perito tem menos agendamento 
     
       vcount := vcount + 1;
     
         
     
       select count (pa.id_periciaagendamento) into vqt 
         from periciaagendamento pa
        where pa.codperito   =  c1.codperito
          and pa.tipopericia = 'EX';
       
       if  vcount = 1 then
         
           vmenor := vqt;
           vperito := c1.codperito;
       
       else 
         
           if vmenor > vqt then
             
             vmenor := vqt;
             vperito := c1.codperito;
          
           end if;    
          
       end if;
     
     end loop;
     
      open c_dados_oficio(poficio);
     fetch c_dados_oficio into vdados_oficio;
     close c_dados_oficio;
     
     if vdados_oficio.localpericia = 2 then
          
        vraj := 1;
        
     else 
          
        vraj := laudo_pkg_agendamento.fnc_define_raj(pdescentralizada => vdados_oficio.descentralizada
                                                    ,praj             => vdados_oficio.raj
                                                    ,pcomarca         => vdados_oficio.comarcaprocesso);
     end if; 
                 
     if vdados_oficio.situacaopericiando = 2 then
        --
        vreupreso := 'S';
        --
     else
        --
        vreupreso := 'N';
        --
     end if;  
  
     for r_valida_prontuario in c_valida_prontuario
     loop
     --
      open c_seq_prontuario_pericial_oficio(r_valida_prontuario.codprontuariopericialoficio);
     fetch c_seq_prontuario_pericial_oficio into vseq_prontuario_pericial_oficio;
     close c_seq_prontuario_pericial_oficio;
        --
          if nvl(vseq_prontuario_pericial_oficio,0) > vseq_maior then
            --
            vseq_maior := vseq_prontuario_pericial_oficio;
            --
          end if;
        --
      end loop;
      
     for r_agenda_sequencia in (select pad.codperitoagendadetalhe
                                ,      pad.horinicio
                                ,      pad.horfim
                                ,      en.codespecialidadenatureza
                                ,      case 
                                       when pt.indefetivo = 'Y' or pt.indcredenciado = 'Y' then 'Y'
                                       else 'N' 
                                       end efetivocadastrado
                                  from peritoagenda                pa
                                ,      peritoagendadetalhe         pad
                                ,      peritogeracaoagenda         pga
                                ,      peritoperfil                pp
                                ,      peritoespecialidadenatureza pen
                                ,      perito                      pt
                                ,      especialidadenatureza       en
                                 where pp.codperito                       = pt.codperito
                                   and pt.indativo                        = 'Y' 
                                   and pa.codperitoagenda                 = pad.codperitoagenda
                                   and pa.qtdpericiasrestantes            >= pqtd_periciando
                                   and pa.datatendimento                  = trunc(pad.horinicio)
                                   and pad.indreservado                    = 'N'
                                   and pad.indencaixe                      = 'N'
                                   and pad.INDATIVO                        = 'Y'
 
                                      --and pad.HORINICIO                       > sysdate !!!!
                                   and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                                        and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                                        or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                                          and pad.HORINICIO > sysdate))
                                   and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
                                   and pga.codperito                      = vperito
                                   and pga.codperitoperfil                = pp.codperitoperfil
                                   and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
                                   and pen.codespecialidadenatureza       = en.codespecialidadenatureza
                                   and en.codespecialidade                = pespecialidade
                                   and pp.zona                           like ('%'||pzona||'%')
                                   and pp.codraj                          = vraj
                                   order by 2 asc
                                   fetch first pqtd_periciando rows only) loop 
                                   
            --                           
            vdata_operacao         := sysdate;
            --
            update peritoagendadetalhe pad
               set pad.indreservado = 'Y'
             where pad.codperitoagendadetalhe = r_agenda_sequencia.codperitoagendadetalhe;
            --
            vprontuariopericial := null;
            --
            open  c_prontuario_pericial(vseq_maior);
            fetch c_prontuario_pericial into vprontuariopericial;
            close c_prontuario_pericial;
            --
            insert into periciaAgendamento(codperito
                                          ,horchegada
                                          ,codprontuariopericialOficio
                                          ,codperitoagendadetalhe
                                          ,codespecialidadenatureza
                                          ,indreupreso
                                          ,indativo
                                          ,codpessoaacompanhante
                                          ,numdocumentoacompanhante
                                          ,datoperacao
                                          ,codusuariooperacao
                                          ,indefetivocadastrado
                                          ,situacao
                                          ,tipo
                                          ,seqagendamento
                                          ,tipopericia
                                          ,peticionamento
                                          ,zona)
                                   values (vperito
                                          ,null--r_agenda_sequencia.horinicio
                                          ,vprontuariopericial
                                          ,r_agenda_sequencia.codperitoagendadetalhe
                                          ,r_agenda_sequencia.codespecialidadenatureza
                                          ,vreupreso
                                          ,'Y'
                                          ,null
                                          ,null
                                          ,vdata_operacao
                                          ,nvl(v('GLOBAL_ID_USUARIO'),1)  -- Integração
                                          ,r_agenda_sequencia.efetivocadastrado
                                          ,'AGENDADA/AGUARDANDO'
                                          ,nvl(ptipo_agendamento,'P')
                                          ,vseq_maior
                                          ,'EX'
                                          ,'PENDENTE'
                                          ,pzona);
            --
            vid_pericia_agendamento := seq_periciaagendamento.currval;
            pidpericiaagendamento   := vid_pericia_agendamento;
            --
            insert into historico_pericia_agendamento (id_periciaagendamento
                                                      ,codperito
                                                      ,codprontuariopericialoficio
                                                      ,codperitoagendadetalhe
                                                      ,codespecialidadenatureza
                                                      ,codusuariooperacao
                                                      ,dataoperacao
                                                      ,indefetivocadastrado
                                                      ,indurgente
                                                      ,indativo
                                                      ,zona)
                                               values (vid_pericia_agendamento
                                                      ,vperito
                                                      ,vprontuariopericial
                                                      ,r_agenda_sequencia.codperitoagendadetalhe
                                                      ,r_agenda_sequencia.codespecialidadenatureza
                                                      ,nvl(v('GLOBAL_ID_USUARIO'),1)  -- Integração
                                                      ,vdata_operacao
                                                      ,r_agenda_sequencia.efetivocadastrado
                                                      ,'N'
                                                      ,'Y'
                                                      ,pzona); 
                --
                open cperitoagenda(r_agenda_sequencia.codperitoagendadetalhe);--vdata_agendamento.codperitoagendadetalhe);
                fetch cperitoagenda into vperitoagenda;
                close cperitoagenda;
         
                if nvl(ptipo_agendamento, 'P') = 'P' then
                --   
                  update peritoagenda pa
                     set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes -1)
                   where pa.codperitoagenda = vperitoagenda.codperitoagenda;
                --          
                elsif nvl(ptipo_agendamento, 'P') = 'A' then
                --    
                  update peritoagenda pa
                     set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes -1)
                   where pa.codperitoagenda = vperitoagenda.codperitoagenda;
                --  
                end if;
                --
                open c_perito_agenda_agendamento(r_agenda_sequencia.codperitoagendadetalhe); --verificar não há certeza se varios pad são para 1 peritoagenda
                fetch c_perito_agenda_agendamento into vcodperitoagenda;
                close c_perito_agenda_agendamento;
                --
                open c_verifica_agenda_completa(vcodperitoagenda);
                fetch c_verifica_agenda_completa into vverifica;
                if c_verifica_agenda_completa%notfound then
                  --
                  open c_define_rotina_portaria(vprontuariopericial);
                  fetch c_define_rotina_portaria into vlocal_pericia;
                  close c_define_rotina_portaria;
                  --
                  open c_data_agenda_completa(vcodperitoagenda);
                  fetch c_data_agenda_completa into vdata;
                  close c_data_agenda_completa;
                  --
                --if vdados_oficio.nomelocalprisao is not null then -- VERIFICAR COM LUCIA SE CASO O AGENDAMENTO PENDENTE FOR DE PRISAO, CHAMAR A LISTA DE PORTARIA DE CDP EM VEZ DA EXTERNO.
                    --
                    laudo_pkg_lista_portaria.prc_gera_lista_portaria_agendamento_externo_completa(pcod_perito       => vperito
                                                                                                 ,pdata_agendamento => to_date(vdata,'DD/MM/YYYY'));
                    --
                --end if;
                  --
                end if;
                close c_verifica_agenda_completa;
                --
        end loop;
        
              laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => pprotocolo
  										 			           ,pstatus    => 'AGENDADO');
                                     
  end prc_agendar_externa_zona;
  --
  procedure prc_agendamento_aprovacao_diretoria(pprotocolo                in number,
                                                poficio                   in number,
                                                pespecialidade            in number,
                                                pnatureza                 in number,
                                                praj                      in number,   
                                                pqtdpericiando            in number,
                                                psituacao_periciando      in varchar2 default null,
                                                ppsiquiatria              in varchar2,
                                                ptipo_agendamento         in varchar2 default null,
                                                pprontuariopericialoficio in number default null,
                                                pcodperito                in number,
                                                pidpericiaagendamento     out number) is

  --
  verro          varchar2(1);
  vqtdpericiando number := pqtdpericiando;
  vpsicologia    varchar2(10);
  vvalida        varchar2(10);
  vqtpericiando  number;
  pcdp           number;
  -- 
  cursor c_prontuario_pericial is
    select ppo.codprontuariopericialoficio
      from prontuariopericialoficio ppo
     where ppo.idprotocolo = pprotocolo
       and ppo.id_oficio   = poficio
       and ppsiquiatria = 'N'
    union
    select ppo.codprontuariopericialoficio
      from prontuariopericialoficio ppo
     where ppo.idprotocolo = pprotocolo
       and ppo.id_oficio   = poficio
       and ppsiquiatria    = 'S'
       and codprontuariopericialoficio not in nvl(laudo_pkg_agendamento.fnc_retorna_protuario_oficio_reu(poficio => poficio, pprotocolo => pprotocolo), 0);
  vprontuariopericial number;
      
  mensagem_erro VARCHAR2(1000);
  --
  cursor c_setor_destino_protocolo is
    select p.setor
    from protocolo p
    where p.id_protocolo = pprotocolo;
  vsetor_destino_protocolo number;

begin
  --
  update oficio o
     set o.especialidade = pespecialidade,
         o.natureza      = pnatureza
   where o.id_oficio     = poficio ;
   commit;
  vqtdpericiando := 1;
  if (ptipo_agendamento = 'A' and  ppsiquiatria = 'S') or (ptipo_agendamento = 'A' and  pqtdpericiando > 1) then
  
      vqtdpericiando := 1;

  end if; 
    --raise_application_error(-20001,'poficio: '||poficio||' pespecialidade: '||pespecialidade||' pnatureza: '||pnatureza||' praj: '||praj||' vqtdpericiando: '||vqtdpericiando||' psituacao_periciando: '||psituacao_periciando||' ppsiquiatria: '||ppsiquiatria||' ptipo_agendamento: '||ptipo_agendamento||' pprontuariopericialoficio: '||pprontuariopericialoficio);
/*
    laudo_pkg_agendamento.prc_valida_agendamento_diretoria(pid_oficio                => poficio
                                                ,pespecialidade            => pespecialidade
                                                ,pnatureza                 => pnatureza
                                                ,praj                      => praj
                                                ,pqtd_periciando           => vqtdpericiando
                                                ,psituacao_periciando      => psituacao_periciando
                                                ,ppsiquiatria              => ppsiquiatria 
                                                ,ptipo_agendamento         => ptipo_agendamento 
                                                ,pprontuariopericialoficio =>pprontuariopericialoficio
                                                ,pcdp                      => null
                                               --retorno
                                                ,perro                     => verro
                                                ,pexiste_mesma_especinat   => vmesma_especialidade_natureza
                                                ,pidpericiaagendamento      =>pidpericiaagendamento);
*/
    --
    -- raise_application_error(-20001,'Acessou aqui: '||verro);
    if nvl(verro, 'N') = 'N' then 
      --
      if vqtdpericiando > 1 then
        --
        laudo_pkg_agendamento.prc_agendar_sequencia(poficio               => poficio
                                                   ,pprotocolo            => pprotocolo
                                                   ,pqtd_periciando       => vqtdpericiando
                                                   ,ptipo_agendamento     => ptipo_agendamento
                                                   ,ppsiquiatria          => ppsiquiatria
                                                   ,pidpericiaagendamento => pidpericiaagendamento);
        --
      else
        --
        --if vmesma_especialidade_natureza = 'N' then
          --
          --raise_application_error(-20001,'poficio: '||poficio||' pprotocolo: '||pprotocolo||' ptipo_agendamento: '||ptipo_agendamento||' ppsiquiatria: '||ppsiquiatria||' pprontuariopericialoficio: '||pprontuariopericialoficio||' pcodperito: '||pcodperito);
 
          --*****
          --prc_agendar_aprovacao_diretoria
          open c_dados_oficio(poficio);
          loop
          fetch c_dados_oficio into vdados_oficio;
          EXIT WHEN c_dados_oficio%NOTFOUND;
          insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
          values ('c_dados_oficio',sysdate,poficio,pprotocolo);
          END LOOP;
          close c_dados_oficio;
          --
          if vdados_oficio.localpericia = 2 then
            
             vraj := 1;
             
          else
            vraj := praj;
          end if;
          -- vdados_oficio.situacaopericiando == 3 ta certo ??
          --raise_application_error(-20002,vdados_oficio.situacaopericiando); 
         -- if vdados_oficio.situacaopericiando = 'Réu/Ré Preso(a)' then --- estava escrito
          if vdados_oficio.situacaopericiando = 2 then
            --
            vreupreso := 'S';
            --
          else
            --
            vreupreso := 'N';
            --
          end if;
          --
          --raise_application_error(-20001,'vdados_oficio.especialidade: '||vdados_oficio.especialidade||' vdados_oficio.natureza: '||vdados_oficio.natureza||' vraj: '||praj||' pcodperito: '||pcodperito);
          open c_perito_agendamento_diretoria(vdados_oficio.especialidade, vdados_oficio.natureza,praj,pcdp,pcodperito);
          loop
          fetch c_perito_agendamento_diretoria into v_perito_agendamento_diretoria;
           EXIT WHEN c_perito_agendamento_diretoria%NOTFOUND;
          insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
          values ('c_perito_agendamento_diretoria',sysdate,poficio,pprotocolo);
          END LOOP;
          close c_perito_agendamento_diretoria;
          --
          --raise_application_error(-20001,'codperito: '||v_perito_agendamento_diretoria.codperito||' pprontuariopericialoficio: '||pprontuariopericialoficio||' v_perito_agendamento_diretoria.codespecialidadenatureza: '||v_perito_agendamento_diretoria.codespecialidadenatureza);
          open c_data_agendamento(pespecialidadenatureza => v_perito_agendamento_diretoria.codespecialidadenatureza
                                 ,pperito                => v_perito_agendamento_diretoria.codperito  
                                 ,praj                   => praj
                                 ,pcdp                   => pcdp);
          loop                       
          fetch c_data_agendamento into vdata_agendamento;
           EXIT WHEN c_data_agendamento%NOTFOUND;
          insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
          values ('c_data_agendamento',sysdate,poficio,pprotocolo);
          END LOOP;
          close c_data_agendamento;
          --
          vdata_agendamento_prontuario := trunc(vdata_agendamento.horinicio);
          --
          update peritoagendadetalhe pad
          set pad.indreservado = 'Y'
          where pad.codperitoagendadetalhe = vdata_agendamento.codperitoagendadetalhe;
          --
          open c_prontuario_pericial;
          loop
            fetch c_prontuario_pericial into vprontuariopericial;
            EXIT WHEN c_prontuario_pericial%NOTFOUND;
            insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
            values ('c_prontuario_pericial',sysdate,poficio,pprotocolo);
          END LOOP;
          close c_prontuario_pericial;
          --
          vdata_operacao := sysdate;
          --
          --raise_application_error(-20001,'v_perito_agendamento_diretoria.codperito: '||v_perito_agendamento_diretoria.codperito||' pprontuariopericialoficio: '||pprontuariopericialoficio||' v_perito_agendamento_diretoria.codespecialidadenatureza: '||v_perito_agendamento_diretoria.codespecialidadenatureza);
          insert into periciaAgendamento
                 (codperito
                 ,horchegada
                 ,codprontuariopericialOficio
                 ,codperitoagendadetalhe
                 ,codespecialidadenatureza
                 ,indreupreso
                 ,indativo
                 ,codpessoaacompanhante
                 ,numdocumentoacompanhante
                 ,datoperacao
                 ,codusuariooperacao
                 ,indefetivocadastrado
                 ,situacao
                 ,tipo
                 ,seqagendamento
                 ,tipopericia
                 ,peticionamento)
          values (v_perito_agendamento_diretoria.codperito
                 ,null--vdata_agendamento.horinicio
                 ,nvl (vprontuariopericial, pprontuariopericialoficio)
                 ,vdata_agendamento.codperitoagendadetalhe
                 ,v_perito_agendamento_diretoria.codespecialidadenatureza
                 ,vreupreso
                 ,'Y' -- Agendamento sempre entra como ativo
                 ,null
                 ,null
                 ,vdata_operacao
                 ,nvl(v('GLOBAL_ID_USUARIO'),1) 
                 ,v_perito_agendamento_diretoria.efetivocadastrado
                 ,'AGENDADA/AGUARDANDO'
                 ,nvl(ptipo_agendamento,'P')
                 ,0
                 ,nvl(ptipo_agendamento,'P')
                 ,'PENDENTE');
          --
          
          vid_pericia_agendamento := seq_periciaagendamento.currval;
     
          pidpericiaagendamento := vid_pericia_agendamento;
          --
         begin 
          insert into historico_pericia_agendamento
                 (id_periciaagendamento
                 ,codperito
                 ,codprontuariopericialoficio
                 ,codperitoagendadetalhe
                 ,codespecialidadenatureza
                 ,codusuariooperacao
                 ,dataoperacao
                 ,indefetivocadastrado
                 ,indurgente
                 ,indativo)
          values (vid_pericia_agendamento
                   ,v_perito_agendamento_diretoria.codperito
                   ,vprontuariopericial
                   ,vdata_agendamento.codperitoagendadetalhe
                   ,v_perito_agendamento_diretoria.codespecialidadenatureza
                   ,nvl(v('GLOBAL_ID_USUARIO'),1) -- Integração
                   ,vdata_operacao
                   ,v_perito_agendamento_diretoria.efetivocadastrado
                   ,'N'
                   ,'Y'); 
    
          exception
          when others then
          mensagem_erro := SQLERRM;
         insert into LOG_AGENDAMENTO(  FLUXO,DATA)
         values ('historico_pericia_agendamento'||mensagem_erro,sysdate);
                      
          --
          end;
          
          open cperitoagenda(vdata_agendamento.codperitoagendadetalhe);
          loop
          fetch cperitoagenda into vperitoagenda;
            EXIT WHEN cperitoagenda%NOTFOUND;
            insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
            values ('cperitoagenda',sysdate,poficio,pprotocolo);
            END LOOP;
          close cperitoagenda;
     
          if nvl(ptipo_agendamento, 'P') = 'P' then
          --   
            update peritoagenda pa
               set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes -1)
             where pa.codperitoagenda = vperitoagenda.codperitoagenda;
          --          
          elsif nvl(ptipo_agendamento, 'P') = 'A' then
          --    
            update peritoagenda pa
               set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes -1)
             where pa.codperitoagenda = vperitoagenda.codperitoagenda;
          --  
          end if;
          
          if ppsiquiatria = 'S' and ptipo_agendamento = 'P' then
          
             laudo_pkg_agendamento.prc_agendar_psicologia(poficio                => poficio
                                                         ,pprotocolo             => pprotocolo
                                                         ,pperito                => v_perito_agendamento_diretoria.codperito
                                                         ,pdatabase              => vdata_agendamento_prontuario
                                                         ,pespecialidadenatureza => v_perito_agendamento_diretoria.codespecialidadenatureza
                                                         ,pefetivocadastrado     => v_perito_agendamento_diretoria.efetivocadastrado
                                                         ,pseqagendamento        => 0
                                                         ,ptipo_agendamento      => ptipo_agendamento
                                                         ,praj                   => praj
                                                         ,pcdp                   => pcdp); 
          
          end if;
          --*****
          --raise_application_error(-20001,'Antes');
          laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => pprotocolo
                                                           ,pstatus    => 'AGENDADO');
          -- laudo_pkg_protocolo.prc_atualiza_status_protocolo
          update protocolo p
          set p.status = 'AGENDADO'
          where p.id_protocolo = pprotocolo;
          --
          open c_setor_destino_protocolo;
          fetch c_setor_destino_protocolo into vsetor_destino_protocolo;
          close c_setor_destino_protocolo;
          --
          insert into historico_protocolo
                 (status
                 ,id_protocolo
                 ,setor_origem
                 ,setor_destino
                 ,usuario
                 ,data_modificacao)
          values ('AGENDADO'
                 ,pprotocolo
                 ,20--1 -- PROTOCOLO AUTOMATICO
                 ,vsetor_destino_protocolo
                 ,nvl(v('GLOBAL_ID_USUARIO'),1)
                 ,sysdate);
          --*****
          --
          update prontuariopericialoficio ppo
          set ppo.dataagendamento = vdata_agendamento_prontuario
          where ppo.id_oficio = poficio;
          --
          insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                    PNATUREZA,
                                    POFICIO,
                                    PTIPO_AGENDAMENTO,
                                    PQTDPERICIANDO,
                                    PCDP,
                                    PPROTOCOLO,
                                    PERRO,
                                    PPSICOLOGIA,
                                    PVALIDA,
                                    PIDPERICIAAGENDAMENTO,
                                    PQTPERICIANDO,
                                    PRAJ,
                                    PSITUACAO_PERICIANDO,
                                    PPSIQUIATRIA,
                                    PPRONTUARIOPERICIALOFICIO,
                                    PEXISTE_MESMA_ESPECINAT,
                                    FLUXO,
                                    DATA)
        
          values                   ( vdados_oficio.especialidade,
                                     vdados_oficio.natureza,
                                     poficio,
                                     ptipo_agendamento,
                                     '',
                                     pcdp,
                                     pprotocolo,
                                    '',
                                     '',
                                     '', 
                                     pidpericiaagendamento,
                                     '', 
                                     vraj, 
                                     vreupreso,
                                     ppsiquiatria, 
                                     vprontuariopericial,
                                    'vlocal_pericia:'||vlocal_pericia,
                                    'prc_agendar',
                                    sysdate);
          commit;
          --
        --
      end if;
      --
    end if;
  -- 
  end prc_agendamento_aprovacao_diretoria;
--
   procedure prc_agendar_aprovacao_diretoria(poficio    	           in number
                                            ,pprotocolo                in number
                                            ,ptipo_agendamento         in varchar2 default null 
                                            ,ppsiquiatria              in varchar2
                                            ,pprontuariopericialoficio in number default null
                                            ,pcdp                      in number default null
                                            ,pcodperito                in number
                                            ,pidpericiaagendamento     out number) is
      --
      cursor c_prontuario_pericial is
        select ppo.codprontuariopericialoficio
          from prontuariopericialoficio ppo
         where ppo.idprotocolo = pprotocolo
           and ppo.id_oficio   = poficio
           and ppsiquiatria = 'N'
        union
        select ppo.codprontuariopericialoficio
          from prontuariopericialoficio ppo
         where ppo.idprotocolo = pprotocolo
           and ppo.id_oficio   = poficio
           and ppsiquiatria    = 'S'
           and codprontuariopericialoficio not in nvl(laudo_pkg_agendamento.fnc_retorna_protuario_oficio_reu(poficio => poficio, pprotocolo => pprotocolo), 0);
      vprontuariopericial number;
      
      mensagem_erro VARCHAR2(1000);
      --
    begin
      raise_application_error(-20001,'v_perito_agendamento_diretoria.codperito: '||v_perito_agendamento_diretoria.codperito||' pprontuariopericialoficio: '||pprontuariopericialoficio||' v_perito_agendamento_diretoria.codespecialidadenatureza: '||v_perito_agendamento_diretoria.codespecialidadenatureza);
      --
      open c_dados_oficio(poficio);
      loop
      fetch c_dados_oficio into vdados_oficio;
      EXIT WHEN c_dados_oficio%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_dados_oficio',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_dados_oficio;
      --
      if vdados_oficio.localpericia = 2 then
        
         vraj := 1;
         
      else
        
        vraj := laudo_pkg_agendamento.fnc_define_raj(pdescentralizada => vdados_oficio.descentralizada
                                                    ,praj             => vdados_oficio.raj
                                                    ,pcomarca         => vdados_oficio.comarcaprocesso);
      end if;
      -- vdados_oficio.situacaopericiando == 3 ta certo ??
      --raise_application_error(-20002,vdados_oficio.situacaopericiando); 
     -- if vdados_oficio.situacaopericiando = 'Réu/Ré Preso(a)' then --- estava escrito
      if vdados_oficio.situacaopericiando = 2 then
        --
        vreupreso := 'S';
        --
      else
        --
        vreupreso := 'N';
        --
	  end if;
      --
      
 
      open c_perito_agendamento_diretoria(vdados_oficio.especialidade, vdados_oficio.natureza,vraj,pcdp,pcodperito);
      loop
      fetch c_perito_agendamento_diretoria into v_perito_agendamento_diretoria;
       EXIT WHEN c_perito_agendamento_diretoria%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_perito_agendamento_diretoria',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_perito_agendamento_diretoria;
      --
     
                                            
      open c_data_agendamento(pespecialidadenatureza => v_perito_agendamento_diretoria.codespecialidadenatureza
                             ,pperito                => v_perito_agendamento_diretoria.codperito  
                             ,praj                   => vraj
                             ,pcdp                   => pcdp);
      loop                       
      fetch c_data_agendamento into vdata_agendamento;
       EXIT WHEN c_data_agendamento%NOTFOUND;
      insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
      values ('c_data_agendamento',sysdate,poficio,pprotocolo);
      END LOOP;
      close c_data_agendamento;
      --
      vdata_agendamento_prontuario := trunc(vdata_agendamento.horinicio);
      --
	  update peritoagendadetalhe pad
	  set pad.indreservado = 'Y'
	  where pad.codperitoagendadetalhe = vdata_agendamento.codperitoagendadetalhe;
	  --
    --if ptipo_agendamento <> 'A'  then
      
        open c_prontuario_pericial;
        loop
        fetch c_prontuario_pericial into vprontuariopericial;
        EXIT WHEN c_prontuario_pericial%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_prontuario_pericial',sysdate,poficio,pprotocolo);
        END LOOP;
        close c_prontuario_pericial;
      --
    --end if;  
    
      
      vdata_operacao := sysdate;
      --
      raise_application_error(-20001,'v_perito_agendamento_diretoria.codperito: '||v_perito_agendamento_diretoria.codperito||' pprontuariopericialoficio: '||pprontuariopericialoficio||' v_perito_agendamento_diretoria.codespecialidadenatureza: '||v_perito_agendamento_diretoria.codespecialidadenatureza);
	  insert into periciaAgendamento
			 (codperito
			 ,horchegada
			 ,codprontuariopericialOficio
			 ,codperitoagendadetalhe
			 ,codespecialidadenatureza
			 ,indreupreso
			 ,indativo
			 ,codpessoaacompanhante
			 ,numdocumentoacompanhante
			 ,datoperacao
			 ,codusuariooperacao
			 ,indefetivocadastrado
			 ,situacao
			 ,tipo
			 ,seqagendamento
       ,tipopericia
       ,peticionamento)
	  values (v_perito_agendamento_diretoria.codperito
			 ,null--vdata_agendamento.horinicio
			 ,nvl (vprontuariopericial, pprontuariopericialoficio)
			 ,vdata_agendamento.codperitoagendadetalhe
			 ,v_perito_agendamento_diretoria.codespecialidadenatureza
			 ,vreupreso
			 ,'Y' -- Agendamento sempre entra como ativo
			 ,null
			 ,null
			 ,vdata_operacao
			 ,nvl(v('GLOBAL_ID_USUARIO'),1) 
			 ,v_perito_agendamento_diretoria.efetivocadastrado
			 ,'AGENDADA/AGUARDANDO'
			 ,nvl(ptipo_agendamento,'P')
			 ,0
       ,nvl(ptipo_agendamento,'P')
       ,'PENDENTE');
      --
      
      vid_pericia_agendamento := seq_periciaagendamento.currval;
 
      pidpericiaagendamento := vid_pericia_agendamento;
	  --
     begin 
	  insert into historico_pericia_agendamento
        	 (id_periciaagendamento
        	 ,codperito
        	 ,codprontuariopericialoficio
        	 ,codperitoagendadetalhe
        	 ,codespecialidadenatureza
        	 ,codusuariooperacao
        	 ,dataoperacao
        	 ,indefetivocadastrado
        	 ,indurgente
        	 ,indativo)
	  values (vid_pericia_agendamento
	  		   ,v_perito_agendamento_diretoria.codperito
	  		   ,vprontuariopericial
	  		   ,vdata_agendamento.codperitoagendadetalhe
	  		   ,v_perito_agendamento_diretoria.codespecialidadenatureza
	  		   ,nvl(v('GLOBAL_ID_USUARIO'),1) -- Integração
	  		   ,vdata_operacao
	  		   ,v_perito_agendamento_diretoria.efetivocadastrado
	  		   ,'N'
	  		   ,'Y'); 

      exception
      when others then
      mensagem_erro := SQLERRM;
     insert into LOG_AGENDAMENTO(  FLUXO,DATA)
     values ('historico_pericia_agendamento'||mensagem_erro,sysdate);
                  
      --
      end;
      
      open cperitoagenda(vdata_agendamento.codperitoagendadetalhe);
      loop
      fetch cperitoagenda into vperitoagenda;
        EXIT WHEN cperitoagenda%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('cperitoagenda',sysdate,poficio,pprotocolo);
        END LOOP;
      close cperitoagenda;
 
      if nvl(ptipo_agendamento, 'P') = 'P' then
      --   
        update peritoagenda pa
           set pa.qtdpericiasrestantes = (vperitoagenda.qtdpericiasrestantes -1)
         where pa.codperitoagenda = vperitoagenda.codperitoagenda;
      --          
      elsif nvl(ptipo_agendamento, 'P') = 'A' then
      --    
        update peritoagenda pa
           set pa.qtdavaliacoesrestantes = (vperitoagenda.qtdavaliacoesrestantes -1)
         where pa.codperitoagenda = vperitoagenda.codperitoagenda;
      --  
      end if;
      
      if ppsiquiatria = 'S' and ptipo_agendamento = 'P' then
      
         laudo_pkg_agendamento.prc_agendar_psicologia(poficio                => poficio
                                                     ,pprotocolo             => pprotocolo
                                                     ,pperito                => v_perito_agendamento_diretoria.codperito
                                                     ,pdatabase              => vdata_agendamento_prontuario
                                                     ,pespecialidadenatureza => v_perito_agendamento_diretoria.codespecialidadenatureza
                                                     ,pefetivocadastrado     => v_perito_agendamento_diretoria.efetivocadastrado
                                                     ,pseqagendamento        => 0
                                                     ,ptipo_agendamento      => ptipo_agendamento
                                                     ,praj                   => vraj
                                                     ,pcdp                   => pcdp); 
      
      end if;
      --
      laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => pprotocolo
  										 			   ,pstatus    => 'AGENDADO');
      --
      update prontuariopericialoficio ppo
	  set ppo.dataagendamento = vdata_agendamento_prontuario
	  where ppo.id_oficio = poficio;
      --
      -- LISTA DE PORTARIA
      open c_perito_agenda_agendamento(vdata_agendamento.codperitoagendadetalhe);
      loop
      fetch c_perito_agenda_agendamento into vcodperitoagenda;
      EXIT WHEN c_perito_agenda_agendamento%NOTFOUND;
        insert into LOG_AGENDAMENTO(  FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_perito_agenda_agendamento',sysdate,poficio,pprotocolo);
        END LOOP;
      close c_perito_agenda_agendamento;
      --
      open c_verifica_agenda_completa(vcodperitoagenda);
      loop
      fetch c_verifica_agenda_completa into vverifica;
       EXIT WHEN c_verifica_agenda_completa%NOTFOUND;
        insert into LOG_AGENDAMENTO( FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_verifica_agenda_completa',sysdate,poficio,pprotocolo);
        END LOOP;
      if c_verifica_agenda_completa%notfound then
        --
        open c_define_rotina_portaria(vprontuariopericial);
        loop
        fetch c_define_rotina_portaria into vlocal_pericia;
        EXIT WHEN c_define_rotina_portaria%NOTFOUND;
        insert into LOG_AGENDAMENTO( FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_define_rotina_portaria',sysdate,poficio,pprotocolo);
        END LOOP;
        close c_define_rotina_portaria;
        --
        open c_data_agenda_completa(vcodperitoagenda);
        loop
        fetch c_data_agenda_completa into vdata;
         EXIT WHEN c_data_agenda_completa%NOTFOUND;
        insert into LOG_AGENDAMENTO( FLUXO,DATA,POFICIO,PPROTOCOLO)
        values ('c_data_agenda_completa',sysdate,poficio,pprotocolo);
        END LOOP;
        close c_data_agenda_completa;
        --
        if vlocal_pericia = 2 then -- CAPITAL
          --
         
          if vdados_oficio.nomelocalprisao is not null then
            --
           -- raise_application_error(-20002,to_date(to_char(vdata,'DD/MM/YYYY'))); 
            insert into LOG_AGENDAMENTO( FLUXO,DATA)
            values ('1 prc_gera_lista_portaria_cdp_completa iniciar'||to_char(vdata,'DD/MM/YYYY'),sysdate);
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento_diretoria.codperito,to_date(to_char(vdata,'DD/MM/YYYY')));
            --
          else
            --
            insert into LOG_AGENDAMENTO( FLUXO,DATA)
            values ('2 prc_gera_lista_portaria_cdp_completa iniciar'||to_char(vdata,'DD/MM/YYYY'),sysdate);
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_capital_completa(v_perito_agendamento_diretoria.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        elsif vlocal_pericia = 3 then -- RAJ
          --
          if vreupreso = 'S' then
            if vdados_oficio.nomelocalprisao is not null then
              laudo_pkg_lista_portaria.prc_gera_lista_portaria_cdp_completa(v_perito_agendamento_diretoria.codperito,to_date(vdata,'DD/MM/YYYY'));
            end if;
            --
          else
            --
            insert into LOG_AGENDAMENTO( FLUXO,DATA)
            values ('2 prc_gera_lista_portaria_raj_completa iniciar RAJ '||to_char(vdata,'DD/MM/YYYY'),sysdate);
            laudo_pkg_lista_portaria.prc_gera_lista_portaria_raj_completa(v_perito_agendamento_diretoria.codperito,to_date(vdata,'DD/MM/YYYY'));
            --
          end if;
          --
        end if;
        --
      end if;
      close c_verifica_agenda_completa;
      --
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 vdados_oficio.especialidade,
                                 vdados_oficio.natureza,
                                 poficio,
                                 ptipo_agendamento,
                                 '',
                                 pcdp,
                                 pprotocolo,
                                '',
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 '', 
                                 vraj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                'vlocal_pericia:'||vlocal_pericia,
                                'prc_agendar',
                                sysdate);
      commit;
      --
      exception
      when others then
      mensagem_erro := SQLERRM;
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 vdados_oficio.especialidade,
                                 vdados_oficio.natureza,
                                 poficio,
                                 ptipo_agendamento,
                                 '',
                                 pcdp,
                                 pprotocolo,
                                 mensagem_erro,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 '', 
                                 vraj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                'vlocal_pericia:'||vlocal_pericia,
                                'prc_agendar',
                                sysdate);
        --rollback;
      
    end prc_agendar_aprovacao_diretoria;
    --
    procedure prc_valida_agendamento_diretoria(pid_oficio	               in number
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
                                    ,pidpericiaagendamento     out number) is
      --
      erro_tratado exception;
      vqtd_periciando number := pqtd_periciando;
      --

      cursor c_verifica_perfil_agenda is
        select 1 
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pp.codraj                          = praj
          and pcdp                               is null
          union
         select 1 
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pp.codcpd                          = pcdp
          and pcdp                                is not null;
      --
      cursor c_verifica_agenda_periciando(pqtd_periciando in number) is 
        select pad.codperitoagendadetalhe codigo_agenda
        ,      trunc(pad.horinicio)       data_agenda
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    peritogeracaoagenda         pga
        ,    peritoagenda                pa
        ,    peritoagendadetalhe         pad
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pga.codperitoperfil                = pp.codperitoperfil
          and pga.codperito                      = pp.codperito
          and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.datatendimento                  = trunc(pad.horinicio)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.indativo                       = 'Y'
          --and pad.horinicio                      > sysdate -- removido devido a parametrizacao
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pp.codraj                          = praj
          and pcdp                               is null
          and ((pa.qtdpericiasrestantes >= pqtd_periciando and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes >= pqtd_periciando and ptipo_agendamento = 'A'))
        --and pqtd_periciando                    = 1
          and not exists (select 1
                          from rajdianaotrabalhado rnt
                          where rnt.codraj              = pp.codraj
                            and rnt.datdianaotrabalhado = trunc(pad.horinicio))
          and pad.codperitoagendadatastrancadas is null
          union 
        select pad.codperitoagendadetalhe codigo_agenda
        ,      trunc(pad.horinicio)       data_agenda
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    peritogeracaoagenda         pga
        ,    peritoagenda                pa
        ,    peritoagendadetalhe         pad
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pga.codperitoperfil                = pp.codperitoperfil
          and pga.codperito                      = pp.codperito
          and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.datatendimento                  = trunc(pad.horinicio)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.indativo                       = 'Y'
          --and pad.horinicio                      > sysdate -- removido devido a parametrizacao
          and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          and pp.codcpd                          = pcdp
          and pcdp                                is not null
          and ((pa.qtdpericiasrestantes >= pqtd_periciando and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes >= pqtd_periciando and ptipo_agendamento = 'A'))
        --and pqtd_periciando                    = 1
          and not exists (select 1
                          from rajdianaotrabalhado rnt
                          where rnt.codraj              = pp.codraj
                            and rnt.datdianaotrabalhado = trunc(pad.horinicio))
          and pad.codperitoagendadatastrancadas is null;
          
 
       vverifica_agenda_periciando c_verifica_agenda_periciando%rowtype;
   
    --
    cursor c_define_prontuario is
    select o.numeroprocesso
        ,  ppo.idprontuariopericial
        ,  ppo.codprontuariopericialoficio
        ,  ppo.idprotocolo
    from prontuariopericialoficio ppo,
         oficio o
    where ppo.id_oficio = o.id_oficio 
      and ppo.codprontuariopericialoficio = pprontuariopericialoficio;
    --
    cursor c_prontuario is
		select o.numeroprocesso
        ,  ppo.idprontuariopericial
        ,  ppo.codprontuariopericialoficio
        ,  ppo.idprotocolo
	  	from prontuariopericialoficio ppo,
           oficio o
		 where ppo.id_oficio = o.id_oficio
       and ppo.id_oficio = pid_oficio;
     vprontuario c_prontuario%rowtype;
     --
      cursor c_mesma_especialidade_natureza(pprontuario in number) is
		select 1
		from prontuariopericialoficio ppo
		where ppo.idprontuariopericial = pprontuario
      and exists (select 1
                  from periciaagendamento pa
                  ,    peritoagendadetalhe pad
                  ,    especialidadenatureza en
              where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
                and pa.codperitoagendadetalhe      = pad.codperitoagendadetalhe
                and pa.indativo                    = 'Y'
                --and pad.horinicio                  > sysdate !!!!
                and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                   and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                    and pad.HORINICIO > sysdate))
                and pa.codespecialidadenatureza    = en.codespecialidadenatureza
                and en.codnatureza                 = pnatureza
                and en.codespecialidade            = pespecialidade
                and pa.tipo                        = ptipo_agendamento);
      --
     cursor c_mesma_especialidade_natureza_processo(pprontuario in number, pprocesso in varchar2) is 
       select 1
        from prontuariopericialoficio ppo,
             oficio o
        where ppo.idprontuariopericial = pprontuario
          and ppo.id_oficio            = o.id_oficio
          and o.numeroprocesso         <> pprocesso
          and exists (select 1
                      from periciaagendamento pa
                      ,    peritoagendadetalhe pad
                      ,    especialidadenatureza en
                      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
                        and pa.codperitoagendadetalhe      = pad.codperitoagendadetalhe
                        and pa.indativo                    = 'Y'
                        and pad.horinicio                  > sysdate 
                        /*and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                           and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                        or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                            and pad.HORINICIO > sysdate))*/
                        and pa.codespecialidadenatureza    = en.codespecialidadenatureza
                        and en.codnatureza                 = pnatureza
                        and en.codespecialidade            = pespecialidade
                        and pa.tipo                        = ptipo_agendamento);      
      
      cursor c_especialidade_natureza is
        select en.codespecialidadenatureza
        from especialidadenatureza en
        where en.codespecialidade = pespecialidade
          and en.codnatureza 	  = pnatureza;
      vcod_especialidade_natureza number;
      --
      cursor c_agendamento_mesma_especialidade_natureza(pprontuario 			    in number
        											                         ,pcod_especialidade_natureza in number) is
         select min(pa.codperitoagendadetalhe) codperitoagendadetalhe
          ,     pa.codperito
          ,     pa.indefetivocadastrado
           from periciaagendamento pa,
                prontuariopericialoficio ppo,
                peritoagendadetalhe pad 
          where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
            and pa.codespecialidadenatureza    = pcod_especialidade_natureza
            and ppo.idprontuariopericial       = pprontuario
            and pad.codperitoagendadetalhe     = pa.codperitoagendadetalhe
            --and pad.horinicio > sysdate !!!!
            and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                and pad.HORINICIO > sysdate))
          group by pa.codperito,
                   pa.indefetivocadastrado;
      vdados_agendamento_mesma_especinat c_agendamento_mesma_especialidade_natureza%rowtype;
      --
      cursor c_verifica_agenda_reu(pdata_base_periciando in date) is 
        select 1 
        from especialidadenatureza       en
        ,    peritoespecialidadenatureza pen
        ,    peritoperfil                pp
        ,    peritogeracaoagenda         pga
        ,    peritoagenda                pa
        ,    peritoagendadetalhe         pad
        ,    perito                      pt
        where pp.codperito                       = pt.codperito
          and pt.indativo                        = 'Y' 
          and en.codespecialidade                = pespecialidade
          and en.codnatureza                     = pnatureza 
          and en.codespecialidadenatureza        = pen.codespecialidadenatureza
          and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
          and pga.codperitoperfil                = pp.codperitoperfil
          and pga.codperito                      = pp.codperito
          and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
          and pa.codperitoagenda                 = pad.codperitoagenda
          and pa.datatendimento                  = trunc(pad.horinicio)
          and pad.indreservado                   = 'N'
          and pad.indencaixe                     = 'N'
          and pad.indativo                       = 'Y'
          and pp.codraj                          = praj
          and pcdp                             is null
          and trunc(pad.horinicio)				      >= trunc(pdata_base_periciando) + 7
          -- PARAMETRIZACAO???
          and ((pa.qtdpericiasrestantes > 0 and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes > 0 and ptipo_agendamento = 'A'))
        --and pqtd_periciando                    = 1
          and not exists (select 1
                          from rajdianaotrabalhado rnt
                          where rnt.codraj              = pp.codraj
                            and rnt.datdianaotrabalhado = trunc(pad.horinicio))
          and pad.codperitoagendadatastrancadas is null
             union
 
            select 1 
            from especialidadenatureza       en
            ,    peritoespecialidadenatureza pen
            ,    peritoperfil                pp
            ,    peritogeracaoagenda         pga
            ,    peritoagenda                pa
            ,    peritoagendadetalhe         pad
            ,    perito                      pt
            where pp.codperito                       = pt.codperito
              and pt.indativo                        = 'Y'  
              and en.codespecialidade                = pespecialidade
              and en.codnatureza                     = pnatureza 
              and en.codespecialidadenatureza        = pen.codespecialidadenatureza
              and pen.codperitoespecialidadenatureza = pp.codperitoespecialidadenatureza
              and pga.codperitoperfil                = pp.codperitoperfil
              and pga.codperito                      = pp.codperito
              and pga.codperitogeracaoagenda         = pa.codperitogeracaoagenda
              and pa.codperitoagenda                 = pad.codperitoagenda
              and pa.datatendimento                  = trunc(pad.horinicio)
              and pad.indreservado                   = 'N'
              and pad.indencaixe                     = 'N'
              and pad.indativo                       = 'Y'
              and pp.codcpd                          = pcdp
              and pcdp                                is not null
              and trunc(pad.horinicio)				      >= trunc(pdata_base_periciando) + 7
              -- PARAMETRIZACAO???
              and ((pa.qtdpericiasrestantes > 0 and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes > 0 and ptipo_agendamento = 'A'))
            --and pqtd_periciando                    = 1
              and not exists (select 1
                              from rajdianaotrabalhado rnt
                              where rnt.codraj              = pp.codraj
                                and rnt.datdianaotrabalhado = trunc(pad.horinicio))
              and pad.codperitoagendadatastrancadas is null;
      
      --
      vverifica               number;
      vverifica2              number;
      verro                   varchar2(1) := 'N';
      vretorno                varchar2(200);
      vverifica_codigo_agenda number;
      vverifica_data_agenda   date;
      vencontrou_sequencia    varchar2(1) := 'N';
      vdata_base_sequencia    date;
      vqtd_reu                number := 0;
      mensagem_erro           varchar(400);      --
      cursor c_protocolo_oficio is 
        select p.id_protocolo
        from protocolo p 
    	where p.id_oficio = pid_oficio;
      vprotocolo protocolo.id_protocolo%type;
      --
      cursor c_prontuario_pericial (poficio    in number
        						   ,pprotocolo in number) is
        select ppo.codprontuariopericialoficio
          from prontuariopericialoficio ppo
         where ppo.idprotocolo = pprotocolo
           and ppo.id_oficio   = poficio
           and ppsiquiatria = 'N'
        union
        select ppo.codprontuariopericialoficio
        from prontuariopericialoficio ppo
        where ppo.idprotocolo = pprotocolo
          and ppo.id_oficio   = poficio
          and ppsiquiatria    = 'S'
          and codprontuariopericialoficio not in nvl(laudo_pkg_agendamento.fnc_retorna_protuario_oficio_reu(poficio => poficio, pprotocolo => pprotocolo), 0);
      vprontuariopericial number;
      --
    begin 
      --raise_application_error(-20001,'pid_oficio: '||pid_oficio||' pespecialidade: '||pespecialidade||' pnatureza: '||pnatureza||' praj: '||praj||' ppsiquiatria: '||ppsiquiatria||' ptipo_agendamento: '||ptipo_agendamento);
      --
      perro := 'N';
      
      open c_verifica_perfil_agenda;
      fetch c_verifica_perfil_agenda into vverifica;
 
      if c_verifica_perfil_agenda%notfound then
        --
        verro    := 'S';
        vretorno := 'Agendamento não realizado, perfil de agenda não encontrado!';
        raise erro_tratado;
        --
      end if;
      close c_verifica_perfil_agenda;

    
    if (ptipo_agendamento = 'A' and  ppsiquiatria = 'S') or (ptipo_agendamento = 'A' and  pqtd_periciando > 1) then
      
       vqtd_periciando := 1;
   
    end if;
     
      --
      if ppsiquiatria = 'S' and ptipo_agendamento = 'P' then
      --
          pexiste_mesma_especinat := 'N';
          --
          for r_reu in c_nome_reu(pid_oficio)
          loop
            --
            open c_periciandos_reu(poficio   => pid_oficio
                                  ,pnome_reu => r_reu.nome);
            fetch c_periciandos_reu into vpericiandos_reu;
            if c_periciandos_reu%notfound then
                  close c_periciandos_reu;
            --
            vqtd_reu := vqtd_reu + 1;
            verro    := 'S';
            vretorno := 'Agendamento de psiquiatria não realizado, réu não encontrado!';
            raise erro_tratado;
            --
            end if;
                close c_periciandos_reu;
            --
            end loop;
              --
          if pqtd_periciando = 1 then
            --
            open c_verifica_agenda_periciando(pqtd_periciando);
            fetch c_verifica_agenda_periciando into vverifica_agenda_periciando;
            if c_verifica_agenda_periciando%notfound then
              --
            verro    := 'S';
            vretorno := 'Agendamento de psiquiatria não realizado, agenda não disponível!';
            raise erro_tratado;
            --
            end if;
            close c_verifica_agenda_periciando;
            --
            open c_perito_agendamento(pespecialidade, pnatureza, praj,pcdp);
            fetch c_perito_agendamento into v_perito_agendamento;
            close c_perito_agendamento;
            --  
            open c_especialidade_natureza;
            fetch c_especialidade_natureza into vcod_especialidade_natureza;
            close c_especialidade_natureza;
            --
            open c_data_agendamento(pespecialidadenatureza => vcod_especialidade_natureza
                                   ,praj                   => praj
                                   ,pcdp                   => pcdp );
            fetch c_data_agendamento into vdata_agendamento;
            close c_data_agendamento;
            --   
            open c_verifica_agenda_reu(pdata_base_periciando => vdata_agendamento.horinicio);
            fetch c_verifica_agenda_reu into vverifica;
            if c_verifica_agenda_reu%notfound then
            --
            verro    := 'S';
            vretorno := 'Agendamento de psiquiatria não realizado, agenda não disponível para o réu!';
            raise erro_tratado;
            --
            end if;
            close c_verifica_agenda_reu;
            --
            else
            --
            for r_verifica_agenda_periciando in c_verifica_agenda_periciando(pqtd_periciando)
            loop
            --
            if (nvl(vverifica_codigo_agenda,0) = r_verifica_agenda_periciando.codigo_agenda - 1) and (vverifica_data_agenda = r_verifica_agenda_periciando.data_agenda) then
              --
              vencontrou_sequencia := 'S';
              exit;
              --
            end if;
            --
            vverifica_codigo_agenda := r_verifica_agenda_periciando.codigo_agenda;
            vverifica_data_agenda   := r_verifica_agenda_periciando.data_agenda;
            --
            end loop;
            --
            if vencontrou_sequencia != 'S' then
            --
            verro    := 'S';
            vretorno := 'Agendamento psiquiatria não realizado, agenda não disponível!';
            raise erro_tratado;
            --
            end if;
            --
            open c_perito_agendamento(pespecialidade, pnatureza, praj,pcdp);
            fetch c_perito_agendamento into v_perito_agendamento;
            close c_perito_agendamento;
            --  
            for r_valida_sequencia in (select pad.codperitoagendadetalhe
                         ,      pad.horinicio
                         ,	    pad.horfim
                         from peritoagenda                pa
                         ,    peritoagendadetalhe         pad
                         ,    peritogeracaoagenda         pga
                         ,    peritoperfil                pp
                         ,    peritoespecialidadenatureza pen
                         ,    perito                      pt
                         where pp.codperito                       = pt.codperito
                           and pt.indativo                        = 'Y' 
                           and pa.codperitoagenda                 = pad.codperitoagenda
                           and pa.qtdpericiasrestantes            >= pqtd_periciando
                           and pa.datatendimento                  = trunc(pad.horinicio)
                           and pad.indreservado 	                = 'N'
                           and pad.indencaixe	 	                  = 'N'
                           and pad.INDATIVO 		                  = 'Y'
                           --and pad.HORINICIO					            > sysdate !!!!
                           and ((laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') != 'Desativado' 
                               and pad.HORINICIO > sysdate + laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)'))
                            or (laudo_pkg_servico.fnc_parametro_sistema('Período mínimo para Agendamento de Perícia (em dias)') = 'Desativado' 
                                and pad.HORINICIO > sysdate))
                           and pa.codperitogeracaoagenda          = pga.codperitogeracaoagenda
                           and pga.codperito                      = v_perito_agendamento.codperito
                           and pga.codperitoperfil                = pp.codperitoperfil
                           and pp.codperitoespecialidadenatureza  = pen.codperitoespecialidadenatureza
                           and pen.codespecialidadenatureza       =v_perito_agendamento.codespecialidadenatureza
                           --and ((pa.qtdpericiasrestantes > 0 and ptipo_agendamento = 'P') or (pa.qtdavaliacoesrestantes > 0 and ptipo_agendamento = 'A'))
                         order by pad.horinicio asc
                         fetch first pqtd_periciando rows only)
                loop
            --
            vdata_base_sequencia := r_valida_sequencia.horinicio;
              --
            end loop;
            -- 
            open c_verifica_agenda_reu(pdata_base_periciando => vdata_base_sequencia);
            fetch c_verifica_agenda_reu into vverifica;
            if c_verifica_agenda_reu%notfound then
            --
            verro    := 'S';
            vretorno := 'Agendamento de psiquiatria não realizado, agenda não disponível para o réu!';
            raise erro_tratado;
            --
            end if;
            close c_verifica_agenda_reu;
            --
          end if;
      --
      else -- if ppsquiatria 
      --
          if vqtd_periciando = 1 then
            
    
           if (ptipo_agendamento = 'A' and  ppsiquiatria = 'S') or (ptipo_agendamento = 'A' and  pqtd_periciando > 1) then
           
              open c_define_prontuario;
              fetch c_define_prontuario into vprontuario;
              close c_define_prontuario;
           
           else 
              --
              open c_prontuario;
              fetch c_prontuario into vprontuario;
              close c_prontuario;
              --
           end if;
            --
            pexiste_mesma_especinat := 'N';
            --
            --open c_mesma_especialidade_natureza( pprontuario => vprontuario.idprontuariopericial);
            --fetch c_mesma_especialidade_natureza into vverifica;
            
            --if c_mesma_especialidade_natureza%found then
             --
               --close c_mesma_especialidade_natureza;
               
                pexiste_mesma_especinat := 'S';
/*                
                laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => vprontuario.idprotocolo
                                                                                         ,pstatus    => 'AGENDADO ANTERIORMENTE');

           -- 

           open c_mesma_especialidade_natureza_processo( pprontuario => vprontuario.idprontuariopericial,
                                                         pprocesso   => vprontuario.numeroprocesso);
            fetch c_mesma_especialidade_natureza_processo into vverifica2;
            
            if c_mesma_especialidade_natureza_processo%found then
*/            --
            open c_especialidade_natureza;
            fetch c_especialidade_natureza into vcod_especialidade_natureza;
            close c_especialidade_natureza;
            --
            open c_agendamento_mesma_especialidade_natureza(pprontuario 			      => vprontuario.idprontuariopericial
                                     ,pcod_especialidade_natureza => vcod_especialidade_natureza);
            fetch c_agendamento_mesma_especialidade_natureza into vdados_agendamento_mesma_especinat;
            close c_agendamento_mesma_especialidade_natureza;
                  --
            --
            if psituacao_periciando = 2 then
              --
              vreupreso := 'S';
              --
            else
              --
              vreupreso := 'N';
              --
            end if;
            --
            open c_protocolo_oficio;
            fetch c_protocolo_oficio into vprotocolo;
            close c_protocolo_oficio;
            --
            open c_prontuario_pericial(pid_oficio, vprotocolo);
            fetch c_prontuario_pericial into vprontuariopericial;
            close c_prontuario_pericial;
                  --
            open c_perito_agendamento(pespecialidade, pnatureza, praj,pcdp);
            fetch c_perito_agendamento into v_perito_agendamento;
            close c_perito_agendamento;
            --
            open c_data_agendamento(pespecialidadenatureza => v_perito_agendamento.codespecialidadenatureza
                                   ,praj                   => praj
                                   ,pcdp                   => pcdp);
            fetch c_data_agendamento into vdata_agendamento;
            close c_data_agendamento;
            --
            vdata_agendamento_prontuario := trunc(vdata_agendamento.horinicio);
            --
            insert into periciaAgendamento
                 (codperito
                 ,horchegada
                 ,codprontuariopericialOficio
                 ,codperitoagendadetalhe
                 ,codespecialidadenatureza
                 ,indreupreso
                 ,indativo
                 ,codpessoaacompanhante
                 ,numdocumentoacompanhante
                 ,datoperacao
                 ,codusuariooperacao
                 ,indefetivocadastrado
                 ,situacao
                 ,tipo
                 ,seqagendamento
                 ,tipopericia
                 ,peticionamento)
            values (vdados_agendamento_mesma_especinat.codperito
                 ,null
                 ,vprontuario.codprontuariopericialoficio
                 ,vdados_agendamento_mesma_especinat.codperitoagendadetalhe
                 ,vcod_especialidade_natureza
                 ,vreupreso
                 ,'Y' -- Agendamento sempre entra como ativo
                 ,null
                 ,null
                 ,sysdate
                 ,nvl(v('GLOBAL_ID_USUARIO'),1)
                 ,vdados_agendamento_mesma_especinat.indefetivocadastrado
                 ,'AGENDADA/AGUARDANDO'
                 ,nvl(ptipo_agendamento,'P')
                 ,0
                 ,nvl(ptipo_agendamento,'P')
                 ,'PENDENTE');
            --
            vid_pericia_agendamento := seq_periciaagendamento.currval;
                  --
            insert into historico_pericia_agendamento
                 (id_periciaagendamento
                 ,codperito
                 ,codprontuariopericialoficio
                 ,codperitoagendadetalhe
                 ,codespecialidadenatureza
                 ,codusuariooperacao
                 ,dataoperacao
                 ,indefetivocadastrado
                 ,indurgente
                 ,indativo)
            values (vid_pericia_agendamento
                 ,v_perito_agendamento.codperito
                 ,vprontuariopericial
                 ,vdata_agendamento.codperitoagendadetalhe
                 ,v_perito_agendamento.codespecialidadenatureza
                 ,nvl(v('GLOBAL_ID_USUARIO'),1) -- Integração
                 ,vdata_operacao
                 ,v_perito_agendamento.efetivocadastrado
                 ,'N'
                 ,'Y'); 
                  --
                  laudo_pkg_protocolo.prc_atualiza_status_protocolo(pprotocolo => vprotocolo
                                           ,pstatus    => 'AGENDADO');
                  --
                  update prontuariopericialoficio ppo
              set ppo.dataagendamento = vdata_agendamento_prontuario
              where ppo.id_oficio = pid_oficio;
                  --
               pidpericiaagendamento := vid_pericia_agendamento ;
                
             --end if; --c_mesma_especialidade_natureza_processo
             
             --close c_mesma_especialidade_natureza_processo;
              
            --else -- c_mesma_especialidade_natureza
                  -- 
            open c_verifica_agenda_periciando(vqtd_periciando);
            fetch c_verifica_agenda_periciando into vverifica_agenda_periciando;
            if c_verifica_agenda_periciando%notfound then
              --
       
              verro    := 'S';
              vretorno := 'Agendamento não realizado, agenda não disponível!';
              raise erro_tratado;
              --
            end if;
            close c_verifica_agenda_periciando;
            --
            --end if; -- c_mesma_especialidade_natureza
            --
          else -- Mais de um periciando 1
            --
                --  raise_application_error(-20001, vverifica);
            for r_verifica_agenda_periciando in c_verifica_agenda_periciando(pqtd_periciando)
            loop
            --
            if (nvl(vverifica_codigo_agenda,0) = r_verifica_agenda_periciando.codigo_agenda - 1) and (vverifica_data_agenda = r_verifica_agenda_periciando.data_agenda) then
              --
              vencontrou_sequencia := 'S';
              exit;
              --
            end if;
            --
            vverifica_codigo_agenda := r_verifica_agenda_periciando.codigo_agenda;
            vverifica_data_agenda   := r_verifica_agenda_periciando.data_agenda;
            --
            end loop;
            --
            if vencontrou_sequencia != 'S' then
            --
            verro    := 'S';
            vretorno := 'Agendamento não realizado, agenda não disponível!';
            raise erro_tratado;
            --
            end if;
            --
          end if;
      --
      end if; -- if ppsiquiatria
      --
      
       insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 pid_oficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 vprotocolo,
                                 perro ||' '|| vretorno,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 praj, 
                                 vreupreso,
                                ppsiquiatria, 
                                 vprontuariopericial,
                                pexiste_mesma_especinat,
                                'prc_valida_agendamento',
                                sysdate);

    commit;                           
    exception
      when erro_tratado then
      --insert na estrutura
      --raise_application_error(-20002,vretorno);
           perro := verro;
        insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 pid_oficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 vprotocolo,
                                 perro ||' '|| vretorno,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 praj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                pexiste_mesma_especinat,
                                'prc_valida_agendamento',
                                sysdate);
                                commit;
       when others then
         mensagem_erro := SQLERRM;
       -- raise_application_error(-20002,sqlerrm);
        insert into LOG_AGENDAMENTO(PESPECIALIDADE,
                                PNATUREZA,
                                POFICIO,
                                PTIPO_AGENDAMENTO,
                                PQTDPERICIANDO,
                                PCDP,
                                PPROTOCOLO,
                                PERRO,
                                PPSICOLOGIA,
                                PVALIDA,
                                PIDPERICIAAGENDAMENTO,
                                PQTPERICIANDO,
                                PRAJ,
                                PSITUACAO_PERICIANDO,
                                PPSIQUIATRIA,
                                PPRONTUARIOPERICIALOFICIO,
                                PEXISTE_MESMA_ESPECINAT,
                                FLUXO,
                                DATA)
    
    values                      (
                                 pespecialidade,
                                 pnatureza,
                                 pid_oficio,
                                 ptipo_agendamento,
                                 pqtd_periciando,
                                 pcdp,
                                 vprotocolo,
                                 mensagem_erro,
                                 '',
                                 '', 
                                 pidpericiaagendamento,
                                 pqtd_periciando, 
                                 praj, 
                                 vreupreso,
                                 ppsiquiatria, 
                                 vprontuariopericial,
                                pexiste_mesma_especinat,
                                'prc_valida_agendamento',
                                sysdate);
                                commit;
                                
    end prc_valida_agendamento_diretoria;

end;
/