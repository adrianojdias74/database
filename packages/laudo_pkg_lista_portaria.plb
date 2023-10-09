create or replace package body LAUDO_PKG_LISTA_PORTARIA is
 --26/09/23
  --
  vbody 		   clob;
  vres  		   clob;
  voficio          clob;
  vdocumento 	   blob;
  varquivoassinado clob; 
  vqtd_perito      number;
  --
  vbody_email         varchar2(3000);
  imagem_email        blob;
  imagem_email_base64 clob;
  --
  cursor c_email_imesc1 is
    select pa.valor
    from  parametro_sistema pa
    where pa.descricao = 'E-mail 1 cadastrado para cópia de envio de Lista de Portaria enviado para os peritos';
  --
  cursor c_email_imesc2 is
    select pa.valor
    from  parametro_sistema pa
    where pa.descricao = 'E-mail 2 cadastrado para cópia de envio de Lista de Portaria enviado para os peritos';
  --
  vemail_imesc1 varchar2(80);
  vemail_imesc2 varchar2(80);
  --
  procedure prc_gera_lista_portaria_capital_completa(pcod_perito in number
                                                     ,pdata_agendamento in date) is 
    --
    -- LISTA COMPLETA
    --
    cursor c_perito_lista_completa is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      trunc(pad.horinicio) data_agendamento
      ,      null as codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(sysdate)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.localpericia                 = '2'
        and o.nomelocalprisao              is null
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           = decode(pdata_agendamento,null,trunc(sysdate),trunc(pdata_agendamento))
        and pa.codperito                   = decode(pcod_perito,null,pa.codperito,pcod_perito)
        and pie.despessoaimescemail        is not null
        and pcod_perito is not null
      union
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      trunc(pad.horinicio) data_agendamento
      ,      pp.codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(sysdate)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      ,    peritoagenda             pp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.localpericia                 = '2'
        and o.nomelocalprisao              is null
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           > trunc(sysdate)
        and pie.despessoaimescemail        is not null
        and pp.codperitoagenda = pad.codperitoagenda
        and pp.codperitoagenda not in(select codperitoagenda from portaria_enviada)
        and pcod_perito is null
        order by 1,4;
    --
    cursor c_lista_portaria_completa(pcod_perito       in number
                                    ,pdata_agendamento in date) is 
      select pa.codperito
      ,	     pie.despessoaimescemail
      ,	     pad.horinicio
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,      e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
        and o.localpericia                 = '2'
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and not exists (select 1
        				from peritoagendadetalhe pad2
        				where pad.codperitoagenda  = pad2.codperitoagenda
        			      and pad2.indreservado    = 'N'
        				  and trunc(pad.horinicio) = trunc(pdata_agendamento))
        order by 3;
    --
    cursor c_qtd_agendamentos_perito_completo(pcod_perito       in number
                                             ,pdata_agendamento in date) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						   = 1
        and o.localpericia                 = '2'
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento);
    --
    cursor c_cabecalho_email is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA';
    vbody_email_perito  clob;
    vlista_completa varchar2(1) := 'N';
    --
  begin
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email;
    fetch c_cabecalho_email into vbody_email, imagem_email;
    close c_cabecalho_email;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    -- COMPLETO
    --
    for r_perito_completo in c_perito_lista_completa 
    loop
      insert into portaria_enviada(codperitoagenda,dataenvio,origem)
      values(r_perito_completo.codperitoagenda,sysdate,'Lista Completa Capital');
      commit;
      --
	  open c_qtd_agendamentos_perito_completo(r_perito_completo.codperito, r_perito_completo.data_agendamento);
	  fetch c_qtd_agendamentos_perito_completo into vqtd_perito;
	  close c_qtd_agendamentos_perito_completo;
	  --
	  apex_json.parse(vres);
      --
	  apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); --{
	  apex_json.write('nomeRelatorio', 'Lista_Portaria'); 
	  apex_json.write('dataRemessa', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_completo.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_completo.nompessoa, TRUE);
      apex_json.write('listaPortaria',  '', TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos');  
	  --
      vlista_completa := 'N';
	  for r_lista_portaria_completa in c_lista_portaria_completa(r_perito_completo.codperito, r_perito_completo.data_agendamento)
	  loop
		--
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_completa.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_completa.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_completa.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_completa.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_completa.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_completa.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
        vlista_completa := 'S';
	  end loop;
	  --
	  apex_json.close_all;
	  --
      if vlista_completa = 'S' then
          vbody := apex_json.get_clob_output;
          --
          apex_json.free_output;
          --
          apex_web_service.g_request_headers(1).value := 'application/json';
          apex_web_service.g_request_headers(1).name  := 'Content-Type';
          --
          vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
                                                    ,p_http_method => 'PUT'
                                                  --,p_https_host  => 'imesclaudo.sp.gov.br/'
                                                    ,p_body        => vbody);
          --
          apex_json.parse(vres);
          --
          if apex_web_service.g_status_code = 200 then
            --
            apex_json.parse(vres);
            --
            voficio := vres;
            --
          end if;
          --
          apex_json.parse(voficio);
          varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
          --
          vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
          --
          vbody_email_perito := replace(vbody_email, '@PERITO@', r_perito_completo.nompessoa);
          vbody_email_perito := replace(vbody_email_perito, '@DIA@', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'));
          vbody_email_perito := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito
                                                               ,in_search  => '@IMAGEM@'
                                                               ,in_replace => imagem_email_base64);
          --
          --vbody_email_perito := replace(vbody_email_perito, '@IMAGEM@', imagem_email_base64);
          --
          laudo_pkg_servico.prc_send_mail(p_to          => r_perito_completo.despessoaimescemail --'maria.reis@gpnet.com.br'--
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --

          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);

          --

          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);

      --
      end if; -- if da lista completa
      --
	end loop;
    --

  end prc_gera_lista_portaria_capital_completa;
  --
  procedure prc_gera_lista_portaria_capital_incompleta is 
    --
    -- LISTA INCOMPLETA
    --
    cursor c_perito_lista_incompleta is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      trunc(pad.horinicio) data_agendamento
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(pad.horinicio)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						   = 1 -- CASO QUE PROCESSO COMEÇA NA RAJ DESCENTRALIZADA MAS APENAS A CAPITAL ATENDE
        and o.localpericia                 = '2'
        and o.nomelocalprisao              is null
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and pie.despessoaimescemail        is not null
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
      
    --
    cursor c_lista_portaria_incompleta(pcod_perito       in number
                                      ,pdata_agendamento in date) is 
      select pa.codperito
      ,	     pie.despessoaimescemail
      ,      o.raj
      ,	     pad.horinicio
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,	     e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N')
        order by 4;
    --
    cursor c_qtd_agendamentos_perito_incompleto(pcod_perito       in number
                                               ,pdata_agendamento in date) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
    
    --
    cursor c_cabecalho_email is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA';
    vbody_email_perito  clob;
    --
  begin
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email;
    fetch c_cabecalho_email into vbody_email, imagem_email;
    close c_cabecalho_email;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    -- INCOMPLETO
    --
    for r_perito_incompleto in c_perito_lista_incompleta
    loop
      --
      apex_json.parse(vres);
      --
      open c_qtd_agendamentos_perito_incompleto(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento);
	  fetch c_qtd_agendamentos_perito_incompleto into vqtd_perito;
	  close c_qtd_agendamentos_perito_incompleto;
      --
      apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); 
	  apex_json.write('nomeRelatorio', 'Lista_Portaria'); 
	  apex_json.write('dataRemessa', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_incompleto.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_incompleto.nompessoa, TRUE);
      apex_json.write('listaPortaria',  '', TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos'); 
      --
	  for r_lista_portaria_incompleta in c_lista_portaria_incompleta(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento)
	  loop
		--
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_incompleta.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_incompleta.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_incompleta.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_incompleta.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_incompleta.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_incompleta.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
	  end loop;
      --
	  apex_json.close_all;
	  --
	  vbody := apex_json.get_clob_output;
	  --
	  apex_json.free_output;
	  --
	  apex_web_service.g_request_headers(1).value := 'application/json';
	  apex_web_service.g_request_headers(1).name  := 'Content-Type';
	  --
	  vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
												,p_http_method => 'PUT'
											  --,p_https_host  => 'imesclaudo.sp.gov.br/'
												,p_body        => vbody);
	  --
	  apex_json.parse(vres);
	  --
	  if apex_web_service.g_status_code = 200 then
		--
		apex_json.parse(vres);
		--
		voficio := vres;
		--
	  end if;
	  --
	  apex_json.parse(voficio);
	  varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
	  --
	  vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
	  --
      vbody_email_perito := replace(vbody_email, '@PERITO@', r_perito_incompleto.nompessoa);
      vbody_email_perito := replace(vbody_email_perito, '@DIA@', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'));
      vbody_email_perito := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito
                            						       ,in_search  => '@IMAGEM@'
                            						       ,in_replace => imagem_email_base64);
      --
	  laudo_pkg_servico.prc_send_mail(p_to          => r_perito_incompleto.despessoaimescemail
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
	  --
      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --
      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --
    end loop;
    --
  end prc_gera_lista_portaria_capital_incompleta;
  --
  procedure prc_gera_lista_portaria_raj_completa(pcod_perito in number
                                                ,pdata_agendamento in date) is
    --
    -- LISTA COMPLETA
    --
    cursor c_perito_lista_completa is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,      pie.despessoaimescemail
      ,      o.raj
      ,      trunc(pad.horinicio) data_agendamento
      ,      null codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(pad.horinicio)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.localpericia                 = '3'
        and o.nomelocalprisao              is null
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           = decode(pdata_agendamento,null,trunc(sysdate),trunc(pdata_agendamento))
        and pa.codperito                   = decode(pcod_perito,null,pa.codperito,pcod_perito)
        and pie.despessoaimescemail        is not null
        and pcod_perito is not null
     union
      select distinct pa.codperito
      ,      pe.nompessoa
      ,      pie.despessoaimescemail
      ,      o.raj
      ,      trunc(pad.horinicio) data_agendamento
      ,      pp.codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(pad.horinicio)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      ,    peritoagenda             pp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.localpericia                 = '3'
        and o.nomelocalprisao              is null
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           > trunc(sysdate)
        and pie.despessoaimescemail        is not null
        and pp.codperitoagenda             = pad.codperitoagenda
        and pp.codperitoagenda not in(select codperitoagenda from portaria_enviada)
        and pcod_perito is null
        order by 1,5;
    --
    cursor c_lista_portaria_completa(pcod_perito       in number
                                    ,pdata_agendamento in date
                                    ,praj              in number) is
      select pa.codperito
      ,	     pad.horinicio
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,	     e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
        and o.localpericia                 = '3'
        and o.raj                          = praj
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = to_date(pdata_agendamento,'DD/MM/YYYY')
        and not exists (select 1
        			    from peritoagendadetalhe pad2
        			    where pad.codperitoagenda  = pad2.codperitoagenda
          			      and pad2.indreservado    = 'N'
                          and trunc(pad.horinicio) = to_date(pdata_agendamento,'DD/MM/YYYY'))--trunc(sysdate));
        order by 2;
    --
    cursor c_qtd_agendamentos_perito_completo(pcod_perito       in number
                                             ,pdata_agendamento in date
                                             ,praj              in number) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						  != 1
        and o.localpericia                 = '3'
        and o.raj                          = praj
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = to_date(pdata_agendamento,'DD/MM/YYYY');
    --
    cursor c_cabecalho_email_raj is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA_RAJ';
    vbody_email_perito_raj clob;
    --
    cursor c_descricao_raj(pcod_raj in number) is 
      select r.desraj
      from raj r
      where r.codraj = pcod_raj; 
    vdescricao_raj varchar2(100);
    --
    vquery clob;
    vlista_completa varchar2(1) := 'N';
    --
  begin
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email_raj;
    fetch c_cabecalho_email_raj into vbody_email, imagem_email;
    close c_cabecalho_email_raj;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    -- COMPLETO
    --
    for r_perito_completo in c_perito_lista_completa
    loop
      --
      insert into portaria_enviada(codperitoagenda,dataenvio,origem)
      values(r_perito_completo.codperitoagenda,sysdate,'Lista Completa RAJ');
      commit;
      --
      open c_qtd_agendamentos_perito_completo(r_perito_completo.codperito, r_perito_completo.data_agendamento, r_perito_completo.raj);
	  fetch c_qtd_agendamentos_perito_completo into vqtd_perito;
	  close c_qtd_agendamentos_perito_completo;
      --
      open c_descricao_raj(r_perito_completo.raj);
      fetch c_descricao_raj into vdescricao_raj;
      close c_descricao_raj;
      --
      --vdescricao_raj := laudo_pkg_util.fnc_convert_special_char(vdescricao_raj);
      --
      apex_json.parse(vres);
      --
      apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); 
	  apex_json.write('nomeRelatorio', 'Lista_Portaria'); 
	  apex_json.write('dataRemessa', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_completo.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_completo.nompessoa, TRUE);
      apex_json.write('listaPortaria',  ' - Descentralizada - '||vdescricao_raj, TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos');  
      --
      vlista_completa := 'N';
	  for r_lista_portaria_completa in c_lista_portaria_completa(r_perito_completo.codperito, r_perito_completo.data_agendamento, r_perito_completo.raj)
	  loop
        --
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_completa.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_completa.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_completa.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_completa.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_completa.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_completa.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
        vlista_completa := 'S';
	  end loop;
      --
	  apex_json.close_all;
	  --
      if vlista_completa = 'S' then

          vbody := apex_json.get_clob_output;
          --
          apex_json.free_output;
          --
          apex_web_service.g_request_headers(1).value := 'application/json';
          apex_web_service.g_request_headers(1).name  := 'Content-Type';
          --
          vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
                                                    ,p_http_method => 'PUT'
                                                  --,p_https_host  => 'imesclaudo.sp.gov.br/'
                                                    ,p_body        => vbody);
          --
          apex_json.parse(vres);
          --
          if apex_web_service.g_status_code = 200 then
            --
            apex_json.parse(vres);
            --
            voficio := vres;
            --
          end if;
          --
          apex_json.parse(voficio);
          varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
          --
          vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
          --
          vbody_email_perito_raj := replace(vbody_email, '@PERITO@', r_perito_completo.nompessoa);
          vbody_email_perito_raj := replace(vbody_email_perito_raj, '@DIA@', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'));
          vbody_email_perito_raj := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito_raj
                                                                   ,in_search  => '@IMAGEM@'
                                                                   ,in_replace => imagem_email_base64);
          --

          laudo_pkg_servico.prc_send_mail(p_to          => r_perito_completo.despessoaimescemail--'maria.reis@gpnet.com.br'
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria RAJ '
                                         ,p_text_msg    => vbody_email_perito_raj
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --

          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria RAJ '
                                         ,p_text_msg    => vbody_email_perito_raj
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --
          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria RAJ '
                                         ,p_text_msg    => vbody_email_perito_raj
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --

          if r_perito_completo.raj = 2 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj2@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 2'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 3 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj3@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 3'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 4 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj4@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 4'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 5 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj5@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 5'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 6 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj6@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 6'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 7 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'santosdiretoriatecnica@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 7'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 8 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'periciasimesc8raj@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 8'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 9 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'daraj9@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 9'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 10 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'daraj10.1@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 10'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.raj = 29 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'cejusc.dracena@tjsp.jus.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria RAJ 29'
                                           ,p_text_msg    => vbody_email_perito_raj
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          end if;
	  --
      end if; -- if da lista completa
      --
    end loop;
    --
  end prc_gera_lista_portaria_raj_completa;
  --
  procedure prc_gera_lista_portaria_raj_incompleta is 
    --
    -- LISTA INCOMPLETA
    --
    cursor c_perito_lista_incompleta is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      o.raj
      ,      trunc(pad.horinicio) data_agendamento
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(pad.horinicio)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						  != 1
        and o.localpericia                 = '3'
        and o.nomelocalprisao              is null
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and pie.despessoaimescemail        is not null
        --and p.codperito                    = 12 -- ADD TESTE
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
      
    --
    cursor c_lista_portaria_incompleta(pcod_perito       in number
                                      ,pdata_agendamento in date
                                      ,praj              in number) is
      select pa.codperito
      ,	     pad.horinicio
      ,      o.raj
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,	     e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
      --and o.raj						  != 1
        and o.localpericia                 = '3'
        and o.raj                          = praj
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N')
        order by 2;
    --
    cursor c_qtd_agendamentos_perito_incompleto(pcod_perito       in number
                                               ,pdata_agendamento in date
                                               ,praj              in number) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						  != 1
        and o.localpericia                 = '3'
        and o.raj                          = praj
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
    
    --
    cursor c_cabecalho_email_raj is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA_RAJ';
    vbody_email_perito_raj clob;
    --
    cursor c_descricao_raj(pcod_raj in number) is 
      select r.desraj
      from raj r
      where r.codraj = pcod_raj; 
    vdescricao_raj varchar2(100);
    --
  begin
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email_raj;
    fetch c_cabecalho_email_raj into vbody_email, imagem_email;
    close c_cabecalho_email_raj;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    --
    -- INCOMPLETO
    --
    for r_perito_incompleto in c_perito_lista_incompleta
    loop
      --
      open c_qtd_agendamentos_perito_incompleto(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento, r_perito_incompleto.raj);
	  fetch c_qtd_agendamentos_perito_incompleto into vqtd_perito;
	  close c_qtd_agendamentos_perito_incompleto;
      --
      open c_descricao_raj(r_perito_incompleto.raj);
      fetch c_descricao_raj into vdescricao_raj;
      close c_descricao_raj;
      --
      --vdescricao_raj := laudo_pkg_util.fnc_convert_special_char(vdescricao_raj);
      --
      apex_json.parse(vres);
      --
      apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); --{
	  apex_json.write('nomeRelatorio', 'Lista_Portaria');
	  apex_json.write('dataRemessa', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_incompleto.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_incompleto.nompessoa, TRUE);
      apex_json.write('listaPortaria',  ' - Descentralizada - '||vdescricao_raj, TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos');
      --
	  for r_lista_portaria_incompleta in c_lista_portaria_incompleta(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento, r_perito_incompleto.raj)
	  loop
		--
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_incompleta.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_incompleta.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_incompleta.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_incompleta.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_incompleta.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_incompleta.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
	  end loop;
      --
	  apex_json.close_all;
	  --
	  vbody := apex_json.get_clob_output;
	  --
	  apex_json.free_output;
	  --
	  apex_web_service.g_request_headers(1).value := 'application/json';
	  apex_web_service.g_request_headers(1).name  := 'Content-Type';
	  --
	  vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
												,p_http_method => 'PUT'
											  --,p_https_host  => 'imesclaudo.sp.gov.br/'
												,p_body        => vbody);
	  --
	  apex_json.parse(vres);
	  --
	  if apex_web_service.g_status_code = 200 then
		--
		apex_json.parse(vres);
		--
		voficio := vres;
		--
	  end if;
	  --
	  apex_json.parse(voficio);
	  varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
	  --
	  vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
	  --
      vbody_email_perito_raj := replace(vbody_email, '@PERITO@', r_perito_incompleto.nompessoa);
      vbody_email_perito_raj := replace(vbody_email_perito_raj, '@DIA@', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'));
      vbody_email_perito_raj := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito_raj
                            						           ,in_search  => '@IMAGEM@'
                            						           ,in_replace => imagem_email_base64);
      --
	  laudo_pkg_servico.prc_send_mail(p_to          => r_perito_incompleto.despessoaimescemail--'maria.reis@gpnet.com.br'
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria RAJ '
									 ,p_text_msg    => vbody_email_perito_raj
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
	  --

      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria RAJ '
									 ,p_text_msg    => vbody_email_perito_raj
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --
      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria RAJ '
									 ,p_text_msg    => vbody_email_perito_raj
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --

	  if r_perito_incompleto.raj = 2 then
		--
		laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj2@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 2'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 3 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj3@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 3'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 4 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj4@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 4'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 5 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj5@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 5'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 6 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'periciasraj6@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 6'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 7 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'santosdiretoriatecnica@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 7'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 8 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'periciasimesc8raj@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 8'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 9 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'daraj9@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 9'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 10 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'daraj10.1@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 10'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.raj = 29 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'cejusc.dracena@tjsp.jus.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria RAJ 29'
									   ,p_text_msg    => vbody_email_perito_raj
									   ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
	  end if;
      --
    end loop;
    --
  end prc_gera_lista_portaria_raj_incompleta;
  --
  procedure prc_gera_lista_portaria_cdp_completa(pcod_perito in number
                                                ,pdata_agendamento in date) is
    --
    -- LISTA COMPLETA
    --
    cursor c_perito_lista_completa is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,      pie.despessoaimescemail
      ,      o.raj
      ,      o.nomelocalprisao
      ,      o.enderecoprisao
      ,      trunc(pad.horinicio) data_agendamento
      ,      null codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	where trunc(pad2.HORINICIO) = trunc(sysdate)) qtd_total
      ,      ofp.codigo_cdp
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      ,    oficiopericiando         ofp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           = decode(pdata_agendamento,null,trunc(sysdate),trunc(pdata_agendamento))
        and p.codperito					   = decode(pcod_perito,null,p.codperito,pcod_perito)
        and pie.despessoaimescemail        is not null
        and ofp.id_oficio_periciando       = ppo.id_oficio_periciando
        and ofp.id_oficio                  = o.id_oficio
        and (ofp.codigo_cdp                 is not null or o.nomelocalprisao is not null)
        and pcod_perito is not null
     union
      select distinct pa.codperito
      ,      pe.nompessoa
      ,      pie.despessoaimescemail
      ,      o.raj
      ,      o.nomelocalprisao
      ,      o.enderecoprisao
      ,      trunc(pad.horinicio) data_agendamento
      ,      pp.codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	where trunc(pad2.HORINICIO) = trunc(sysdate)) qtd_total
      ,      ofp.codigo_cdp
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      ,    oficiopericiando         ofp
      ,    peritoagenda             pp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           > trunc(sysdate)
        --and p.codperito					   = decode(pcod_perito,null,p.codperito,pcod_perito)
        and pie.despessoaimescemail        is not null
        and ofp.id_oficio_periciando       = ppo.id_oficio_periciando
        and ofp.id_oficio                  = o.id_oficio
        and (ofp.codigo_cdp                 is not null or o.nomelocalprisao is not null)
        and pp.codperitoagenda             = pad.codperitoagenda
        and pp.codperitoagenda not in(select codperitoagenda from portaria_enviada)
        --and p.codperito = 111
        and pcod_perito is null
        order by 1,7;
    --
    cursor c_lista_portaria_completa(pcod_perito       in number
                                    ,pdata_agendamento in date) is
      select pa.codperito
      ,	     pad.horinicio
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,	     e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      ,    oficiopericiando         ofp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and ofp.id_oficio_periciando       = ppo.id_oficio_periciando
        and ofp.id_oficio                  = o.id_oficio
        and (ofp.codigo_cdp                 is not null or o.nomelocalprisao is not null)
        and not exists (select 1
        			    from peritoagendadetalhe pad2
        			    where pad.codperitoagenda  = pad2.codperitoagenda
          			      and pad2.indreservado    = 'N'
                          and trunc(pad.horinicio) = trunc(pdata_agendamento))--trunc(sysdate));
     order by 2;
    --
    cursor c_qtd_agendamentos_perito_completo(pcod_perito       in number
                                             ,pdata_agendamento in date) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      ,    oficiopericiando         ofp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and ofp.id_oficio_periciando       = ppo.id_oficio_periciando
        and ofp.id_oficio                  = o.id_oficio
        and (ofp.codigo_cdp                 is not null or o.nomelocalprisao is not null);
    --
    cursor c_cabecalho_email_cdp is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA';
    vbody_email_perito  clob;
    vlista_completa varchar2(1) := 'N';
    --
  begin
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email_cdp;
    fetch c_cabecalho_email_cdp into vbody_email, imagem_email;
    close c_cabecalho_email_cdp;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    --
    -- COMPLETO
    --
    for r_perito_completo in c_perito_lista_completa
    loop
      --
      insert into portaria_enviada(codperitoagenda,dataenvio,origem)
      values(r_perito_completo.codperitoagenda,sysdate,'Lista Completa CDP');
      commit;
      --
      open c_qtd_agendamentos_perito_completo(r_perito_completo.codperito, r_perito_completo.data_agendamento);
	  fetch c_qtd_agendamentos_perito_completo into vqtd_perito;
	  close c_qtd_agendamentos_perito_completo;
      --
      apex_json.parse(vres);
      --
      apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); --{
	  apex_json.write('nomeRelatorio', 'Lista_Portaria'); 
	  apex_json.write('dataRemessa', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_completo.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_completo.nompessoa||' - CDP', TRUE);
      apex_json.write('listaPortaria',  'Lista de Portaria', TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos'); 
      --
      vlista_completa := 'N';
      for r_lista_portaria_completa in c_lista_portaria_completa(r_perito_completo.codperito, r_perito_completo.data_agendamento)
	  loop
		--
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_completa.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_completa.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_completa.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_completa.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_completa.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_completa.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
        vlista_completa := 'S';
	  end loop;
      --
      apex_json.close_all;
	  --
      if vlista_completa = 'S' then
      
          vbody := apex_json.get_clob_output;
          --
          apex_json.free_output;
          --
          apex_web_service.g_request_headers(1).value := 'application/json';
          apex_web_service.g_request_headers(1).name  := 'Content-Type';
          --
          vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
                                                    ,p_http_method => 'PUT'
                                                  --,p_https_host  => 'imesclaudo.sp.gov.br/'
                                                    ,p_body        => vbody);
          --
          apex_json.parse(vres);
          --
          if apex_web_service.g_status_code = 200 then
            --
            apex_json.parse(vres);
            --
            voficio := vres;
            --
          end if;
              
     
          apex_json.parse(voficio);
          varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
          --
          --raise_application_error(-20001,varquivoassinado);
     
            
          
          vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
          --
          vbody_email_perito := replace(vbody_email, '@PERITO@', r_perito_completo.nompessoa);
          vbody_email_perito := replace(vbody_email_perito, '@DIA@', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'));
          vbody_email_perito := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito
                                                               ,in_search  => '@IMAGEM@'
                                                               ,in_replace => imagem_email_base64);
          --
          laudo_pkg_servico.prc_send_mail(p_to          => r_perito_completo.despessoaimescemail
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --

          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --

          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --

          if r_perito_completo.codigo_cdp = 1 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'rtsantos@sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --

          elsif r_perito_completo.codigo_cdp = 2 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'wilsonmarcilio@sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.codigo_cdp = 3 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'rtsantos@sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.codigo_cdp = 4 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'ecodognatto@sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.codigo_cdp = 5 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'cdprpreto@sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.codigo_cdp = 6 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'josjunior@sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.codigo_cdp = 7 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'adalbertogarcia@sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);
            --
          elsif r_perito_completo.codigo_cdp = 8 then
            --
            laudo_pkg_servico.prc_send_mail(p_to          => 'cimic@cdpsjcampos.sap.sp.gov.br'
                                           ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                           ,p_subject     => 'Lista Portaria'
                                           ,p_text_msg    => vbody_email_perito
                                           ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                           ,p_attach_mime => 'application/pdf'
                                           ,p_attach_blob => vdocumento);

          end if;
      --
      end if; --if do lista completa
      --
    end loop;
    --
  end prc_gera_lista_portaria_cdp_completa;
  --
  procedure prc_gera_lista_portaria_cdp_incompleta is
    --
    -- LISTA INCOMPLETA
    --
    cursor c_perito_lista_incompleta is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      o.raj
      ,      o.nomelocalprisao
      ,      o.enderecoprisao
      ,      trunc(pad.horinicio) data_agendamento
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(pad.horinicio)) qtd_total
      ,      ofp.codigo_cdp
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      ,    oficiopericiando         ofp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and pie.despessoaimescemail        is not null
        and ofp.id_oficio_periciando       = ppo.id_oficio_periciando
        and ofp.id_oficio                  = o.id_oficio
        and (ofp.codigo_cdp                 is not null or o.nomelocalprisao is not null)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
      
    --
    cursor c_lista_portaria_incompleta(pcod_perito       in number
                                      ,pdata_agendamento in date) is
      select pa.codperito
      ,	     pad.horinicio
      ,      o.raj
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,	     e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      ,    oficiopericiando         ofp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
      --and o.nomelocalprisao              is not null
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and ofp.id_oficio_periciando       = ppo.id_oficio_periciando
        and ofp.id_oficio                  = o.id_oficio
        and (ofp.codigo_cdp                 is not null or o.nomelocalprisao is not null)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N')
        order by 2;
    --
    cursor c_qtd_agendamentos_perito_incompleto(pcod_perito       in number
                                               ,pdata_agendamento in date) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      ,    oficiopericiando         ofp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and o.nomelocalprisao              is not null
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and ofp.id_oficio_periciando       = ppo.id_oficio_periciando
        and ofp.id_oficio                  = o.id_oficio
        and (ofp.codigo_cdp                 is not null or o.nomelocalprisao is not null)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
    --
    cursor c_cabecalho_email_cdp is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA';
    vbody_email_perito  clob;
    --
  begin 
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email_cdp;
    fetch c_cabecalho_email_cdp into vbody_email, imagem_email;
    close c_cabecalho_email_cdp;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    -- INCOMPLETO
    --
    for r_perito_incompleto in c_perito_lista_incompleta
    loop
      --
      open c_qtd_agendamentos_perito_incompleto(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento);
	  fetch c_qtd_agendamentos_perito_incompleto into vqtd_perito;
	  close c_qtd_agendamentos_perito_incompleto;
      --
      apex_json.parse(vres);
      --
      apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); --{
	  apex_json.write('nomeRelatorio', 'Lista_Portaria CDP');
	  apex_json.write('dataRemessa', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_incompleto.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_incompleto.nompessoa||' - CDP', TRUE);
      apex_json.write('listaPortaria',  'Lista de Portaria', TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos');  
      --
      for r_lista_portaria_incompleta in c_lista_portaria_incompleta(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento)
	  loop
		--
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_incompleta.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_incompleta.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_incompleta.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_incompleta.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_incompleta.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_incompleta.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
	  end loop;
      --
      apex_json.close_all;
	  --
	  vbody := apex_json.get_clob_output;
	  --
	  apex_json.free_output;
	  --
	  apex_web_service.g_request_headers(1).value := 'application/json';
	  apex_web_service.g_request_headers(1).name  := 'Content-Type';
	  --
	  vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
												,p_http_method => 'PUT'
											  --,p_https_host  => 'imesclaudo.sp.gov.br/'
												,p_body        => vbody);
	  --
	  apex_json.parse(vres);
	  --
	  if apex_web_service.g_status_code = 200 then
		--
		apex_json.parse(vres);
		--
		voficio := vres;
		--
	  end if;
	  --
	  apex_json.parse(voficio);
	  varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
	  --
	  vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
	  --
      vbody_email_perito := replace(vbody_email, '@PERITO@', r_perito_incompleto.nompessoa);
      vbody_email_perito := replace(vbody_email_perito, '@DIA@', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'));
      vbody_email_perito := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito
                            						       ,in_search  => '@IMAGEM@'
                            						       ,in_replace => imagem_email_base64);
      --
	  laudo_pkg_servico.prc_send_mail(p_to          => r_perito_incompleto.despessoaimescemail--'maria.reis@gpnet.com.br'
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --

      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --

      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);

      --
      if r_perito_incompleto.codigo_cdp = 1 then
		--
		laudo_pkg_servico.prc_send_mail(p_to          => 'rtsantos@sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.codigo_cdp = 2 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'wilsonmarcilio@sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.codigo_cdp = 3 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'rtsantos@sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.codigo_cdp = 4 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'ecodognatto@sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.codigo_cdp = 5 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'cdprpreto@sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.codigo_cdp = 6 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'josjunior@sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.codigo_cdp = 7 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'adalbertogarcia@sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
        --
      elsif r_perito_incompleto.codigo_cdp = 8 then
        --
        laudo_pkg_servico.prc_send_mail(p_to          => 'cimic@cdpsjcampos.sap.sp.gov.br'
									   ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									   ,p_subject     => 'Lista Portaria'
									   ,p_text_msg    => null
									   ,p_attach_name => 'lista_portaria'
									   ,p_attach_mime => 'application/pdf'
									   ,p_attach_blob => vdocumento);
      end if;
      --
    end loop;
    --
  end prc_gera_lista_portaria_cdp_incompleta;
  --
  procedure prc_gera_lista_portaria_agendamento_externo_completa(pcod_perito in number
                                                                ,pdata_agendamento in date) is 
    --
    -- LISTA COMPLETA
    --
    cursor c_perito_lista_completa is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      trunc(pad.horinicio) data_agendamento
      ,      null codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(sysdate)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.localpericia                 = '2' -- removido 
        and o.nomelocalprisao              is null
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.tipopericia                 = 'EX'
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           = decode(pdata_agendamento,null,trunc(sysdate),trunc(pdata_agendamento))
        and pa.codperito                   = decode(pcod_perito,null,pa.codperito,pcod_perito)
        and pie.despessoaimescemail        is not null
        and pcod_perito is not null
     union
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      trunc(pad.horinicio) data_agendamento
      ,      pp.codperitoagenda
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(sysdate)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      ,    peritoagenda             pp
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.localpericia                 = '2' -- removido 
        and o.nomelocalprisao              is null
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.tipopericia                 = 'EX'
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and trunc(pad.horinicio)           > trunc(sysdate)
        and pie.despessoaimescemail        is not null
        and pp.codperitoagenda             = pad.codperitoagenda
        and pp.codperitoagenda not in(select codperitoagenda from portaria_enviada)
        and pcod_perito is null
        order by 1,4;
    --
    cursor c_lista_portaria_completa(pcod_perito       in number
                                    ,pdata_agendamento in date) is 
      select pa.codperito
      ,	     pie.despessoaimescemail
      ,	     pad.horinicio
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,      e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
      --and o.raj						   = 1
      --and o.localpericia                 = '2' removido
        and pa.tipopericia                 = 'EX'
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento) 
        and not exists (select 1
        				from peritoagendadetalhe pad2
        				where pad.codperitoagenda  = pad2.codperitoagenda
        			      and pad2.indreservado    = 'N'
        				  and trunc(pad.horinicio) = trunc(pdata_agendamento));--trunc(sysdate));
    --
    cursor c_qtd_agendamentos_perito_completo(pcod_perito       in number
                                             ,pdata_agendamento in date) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio				    o
      ,    especialidade		    e
      ,	   peritoagendadetalhe      pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						   = 1
      --and o.localpericia                 = '2' -- removido
        and o.especialidade			       = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.tipopericia                 = 'EX'
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento);
    --
    cursor c_cabecalho_email is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA';
    vbody_email_perito  clob;
    vlista_completa varchar2(1) := 'N';
    --
  begin
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email;
    fetch c_cabecalho_email into vbody_email, imagem_email;
    close c_cabecalho_email;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    -- COMPLETO
    --
    for r_perito_completo in c_perito_lista_completa 
    loop
      --
      insert into portaria_enviada(codperitoagenda,dataenvio,origem)
      values(r_perito_completo.codperitoagenda,sysdate,'Lista Completa Agendamento Externo');
      commit;
	  --
	  open c_qtd_agendamentos_perito_completo(r_perito_completo.codperito, r_perito_completo.data_agendamento);
	  fetch c_qtd_agendamentos_perito_completo into vqtd_perito;
	  close c_qtd_agendamentos_perito_completo;
	  --
	  apex_json.parse(vres);
      --
	  apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); --{
	  apex_json.write('nomeRelatorio', 'Lista_Portaria'); 
	  apex_json.write('dataRemessa', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_completo.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_completo.nompessoa, TRUE);
      apex_json.write('listaPortaria',  '', TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos');  
	  --
      vlista_completa := 'N';
	  for r_lista_portaria_completa in c_lista_portaria_completa(r_perito_completo.codperito, r_perito_completo.data_agendamento)
	  loop
		--
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_completa.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_completa.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_completa.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_completa.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_completa.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_completa.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
        vlista_completa := 'S';
	  end loop;
	  --
	  apex_json.close_all;
	  --
      if vlista_completa = 'S' then
          vbody := apex_json.get_clob_output;
          --
          apex_json.free_output;
          --
          apex_web_service.g_request_headers(1).value := 'application/json';
          apex_web_service.g_request_headers(1).name  := 'Content-Type';
          --
          vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
                                                    ,p_http_method => 'PUT'
                                                  --,p_https_host  => 'imesclaudo.sp.gov.br/'
                                                    ,p_body        => vbody);
          --
          apex_json.parse(vres);
          --
          if apex_web_service.g_status_code = 200 then
            --
            apex_json.parse(vres);
            --
            voficio := vres;
            --
          end if;
          --
          apex_json.parse(voficio);
          varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
          --
          vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
          --
          vbody_email_perito := replace(vbody_email, '@PERITO@', r_perito_completo.nompessoa);
          vbody_email_perito := replace(vbody_email_perito, '@DIA@', to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY'));
          vbody_email_perito := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito
                                                               ,in_search  => '@IMAGEM@'
                                                               ,in_replace => imagem_email_base64);
          --
          --vbody_email_perito := replace(vbody_email_perito, '@IMAGEM@', imagem_email_base64);
          --
          laudo_pkg_servico.prc_send_mail(p_to          => r_perito_completo.despessoaimescemail --'maria.reis@gpnet.com.br'--
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --
          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
          --
          laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
                                         ,p_from        => 'naoresponda01@imesc.sp.gov.br'
                                         ,p_subject     => 'Lista Portaria'
                                         ,p_text_msg    => vbody_email_perito
                                         ,p_attach_name => 'lista_portaria_'||to_char(r_perito_completo.data_agendamento,'DD/MM/YYYY')||'.pdf'
                                         ,p_attach_mime => 'application/pdf'
                                         ,p_attach_blob => vdocumento);
      --
      end if; -- if da lista completa
      --
	end loop;
    --
  end prc_gera_lista_portaria_agendamento_externo_completa;
  --
  procedure prc_gera_lista_portaria_agendamento_externo_incompleto is 
    --
    -- LISTA INCOMPLETA
    --
    cursor c_perito_lista_incompleta is
      select distinct pa.codperito
      ,      pe.nompessoa
      ,	     pie.despessoaimescemail
      ,      trunc(pad.horinicio) data_agendamento
      ,		(select count(*)
        	 from PERITOAGENDADETALHE pad2
        	 where trunc(pad2.HORINICIO) = trunc(pad.horinicio)) qtd_total
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoa                   pe
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						   = 1 -- CASO QUE PROCESSO COMEÇA NA RAJ DESCENTRALIZADA MAS APENAS A CAPITAL ATENDE
      --and o.localpericia                 = '2' --removido 
        and o.nomelocalprisao              is null
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.tipopericia                 = 'EX' --add
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and pi.codpessoa                   = pe.codpessoa
        and pie.despessoaimescemail        is not null
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
      
    --
    cursor c_lista_portaria_incompleta(pcod_perito       in number
                                      ,pdata_agendamento in date) is 
      select pa.codperito
      ,	     pie.despessoaimescemail
      ,      o.raj
      ,	     pad.horinicio
      ,      ppo.idprontuariopericial
      ,	     decode(pa.tipo,'P','Perícia','A','Avaliação') tipo
      ,	     pe.nompessoa nomepericiando
      ,	     e.desespecialidade
      ,	     ppo.numprocesso
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    prontuariopericial		po
      ,    periciando				pc
      ,    pessoa					pe
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
        and ppo.idprontuariopericial	   = po.idprontuariopericial
        and po.codpericiando			   = pc.codpericiando
        and pc.codpessoa			   	   = pe.codpessoa
      --and o.raj						   = 1
      --and o.localpericia                 = '2'
        and pa.tipopericia                 = 'EX'
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
    --
    cursor c_qtd_agendamentos_perito_incompleto(pcod_perito       in number
                                               ,pdata_agendamento in date) is
      select count(*)
      from periciaagendamento       pa
      ,    prontuariopericialoficio ppo
      ,    oficio					o
      ,    especialidade			e
      ,	   peritoagendadetalhe	    pad
      ,	   perito				    p
      ,    pessoaimesc 			    pi
      ,    pessoaimescemail	        pie
      where pa.codprontuariopericialoficio = ppo.codprontuariopericialoficio
        and ppo.id_oficio				   = o.id_oficio
      --and o.raj						   = 1
      --and o.localpericia                 = '2' -- removido
        and o.especialidade				   = e.codespecialidade
        and pa.codperitoagendadetalhe	   = pad.codperitoagendadetalhe
        and pa.tipopericia                 = 'EX'
        and trunc(pad.horinicio) 		   = trunc(sysdate) + 15
        and pa.codperito				   = p.codperito
        and p.codpessoaimesc			   = pi.codpessoaimesc
        and pi.codpessoaimesc			   = pie.codpessoaimesc
        and p.codperito					   = pcod_perito
        and trunc(pad.horinicio)           = trunc(pdata_agendamento)
        and exists (select 1
        		    from peritoagendadetalhe pad2
        			where pad.codperitoagenda  = pad2.codperitoagenda
          			  and pad2.indreservado    = 'N');
    
    --
    cursor c_cabecalho_email is
      select te.body 
      ,      te.imagem_body
      from laudo_template_email te
      where te.tipo = 'LISTA_PORTARIA';
    vbody_email_perito  clob;
    --
  begin
    --
    open c_email_imesc1;
    fetch c_email_imesc1 into vemail_imesc1;
    close c_email_imesc1;
    --
    open c_email_imesc2;
    fetch c_email_imesc2 into vemail_imesc2;
    close c_email_imesc2;
    --
    open c_cabecalho_email;
    fetch c_cabecalho_email into vbody_email, imagem_email;
    close c_cabecalho_email;
    --
    vbody_email         := laudo_pkg_util.fnc_convert_special_char(vbody_email);
    imagem_email_base64 := laudo_pkg_util.fnc_blob_to_base64(imagem_email);
    --
    -- INCOMPLETO
    --
    for r_perito_incompleto in c_perito_lista_incompleta
    loop
      --
      apex_json.parse(vres);
      --
      open c_qtd_agendamentos_perito_incompleto(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento);
	  fetch c_qtd_agendamentos_perito_incompleto into vqtd_perito;
	  close c_qtd_agendamentos_perito_incompleto;
      --
      apex_json.initialize_clob_output;
	  --
	  apex_json.open_object(); 
	  apex_json.write('nomeRelatorio', 'Lista_Portaria'); 
	  apex_json.write('dataRemessa', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'), TRUE);
	  apex_json.write('numeroDaRemessa',  to_char(r_perito_incompleto.qtd_total), TRUE);
	  apex_json.write('totalDePastas',  to_char(vqtd_perito), TRUE);
	  apex_json.write('enviadoPor',  r_perito_incompleto.nompessoa, TRUE);
      apex_json.write('listaPortaria',  '', TRUE);
      apex_json.write('ColunaGenerica',  '', TRUE);
	  apex_json.open_array('objetoLayountLaudos'); 
      --
	  for r_lista_portaria_incompleta in c_lista_portaria_incompleta(r_perito_incompleto.codperito, r_perito_incompleto.data_agendamento)
	  loop
		--
		apex_json.open_object; -- {
		apex_json.write('pasta',  to_char(r_lista_portaria_incompleta.idprontuariopericial), TRUE);
		apex_json.write('requerente',  '', TRUE);
		apex_json.write('motivo',  '', TRUE);
		apex_json.write('numeroProcesso', r_lista_portaria_incompleta.numprocesso, TRUE);
		apex_json.write('documento', '', TRUE);
		apex_json.write('dtDiaAgendamento', '' , TRUE);
		apex_json.write('nomePericiando',  r_lista_portaria_incompleta.nomepericiando, TRUE);
		apex_json.write('enderecoPericia',  '', TRUE);
		apex_json.write('nomeEspecialidadeNaoRealiza', r_lista_portaria_incompleta.desespecialidade, TRUE);
		apex_json.write('nomeTipoPericiaNaoRealiza',  '', TRUE);
		apex_json.write('numeroOficio','', TRUE);
		apex_json.write('cdpEndereco',  '', TRUE);
		apex_json.write('tpOficio',  '', TRUE);
		apex_json.write('acao',  '', TRUE);
	    apex_json.write('ordem',  '', TRUE);
		apex_json.write('numeroPortaria',  '', TRUE);
		apex_json.write('setor',  '', TRUE);
		apex_json.write('vara',  '', TRUE);
		apex_json.write('tipoExame',  r_lista_portaria_incompleta.tipo, TRUE);
		apex_json.write('dataPericia',  '', TRUE);
		apex_json.write('horaPericia',   to_char(r_lista_portaria_incompleta.horinicio,'HH24:MI'), TRUE);
		apex_json.write('juiz',  '', TRUE);
		apex_json.write('DataNaoComparecimento', '',TRUE);
		apex_json.close_object;  --}
	    --
	  end loop;
      --
	  apex_json.close_all;
	  --
	  vbody := apex_json.get_clob_output;
	  --
	  apex_json.free_output;
	  --
	  apex_web_service.g_request_headers(1).value := 'application/json';
	  apex_web_service.g_request_headers(1).name  := 'Content-Type';
	  --
	  vres := apex_web_service.make_rest_request(p_url         => 'https://homologacao.imesclaudo.sp.gov.br/imesc_laudo/api/Oficio/GeracaoRelatorioSemAssinatura' --CS_URL_RECEITA_ADESAO
												,p_http_method => 'PUT'
											  --,p_https_host  => 'imesclaudo.sp.gov.br/'
												,p_body        => vbody);
	  --
	  apex_json.parse(vres);
	  --
	  if apex_web_service.g_status_code = 200 then
		--
		apex_json.parse(vres);
		--
		voficio := vres;
		--
	  end if;
	  --
	  apex_json.parse(voficio);
	  varquivoassinado := apex_json.get_clob (p_path => 'oficioBase64');
	  --
	  vdocumento := laudo_pkg_util.clobbase642blob(p_clob => varquivoassinado);
	  --
      vbody_email_perito := replace(vbody_email, '@PERITO@', r_perito_incompleto.nompessoa);
      vbody_email_perito := replace(vbody_email_perito, '@DIA@', to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY'));
      vbody_email_perito := laudo_pkg_util.fnc_replace_clob(in_source  => vbody_email_perito
                            						       ,in_search  => '@IMAGEM@'
                            						       ,in_replace => imagem_email_base64);
      --
	  laudo_pkg_servico.prc_send_mail(p_to          => r_perito_incompleto.despessoaimescemail
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
	  --
      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc1
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --
      laudo_pkg_servico.prc_send_mail(p_to          => vemail_imesc2
									 ,p_from        => 'naoresponda01@imesc.sp.gov.br'
									 ,p_subject     => 'Lista Portaria'
									 ,p_text_msg    => vbody_email_perito
									 ,p_attach_name => 'lista_portaria_'||to_char(r_perito_incompleto.data_agendamento,'DD/MM/YYYY')||'.pdf'
									 ,p_attach_mime => 'application/pdf'
									 ,p_attach_blob => vdocumento);
      --
    end loop;
    --
  end prc_gera_lista_portaria_agendamento_externo_incompleto;
  --
end LAUDO_PKG_LISTA_PORTARIA;
/