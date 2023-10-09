create or replace package LAUDO_PKG_LISTA_PORTARIA as
 --26/09/23
  --
  procedure prc_gera_lista_portaria_capital_completa(pcod_perito in number
                                                     ,pdata_agendamento in date);
  --
  procedure prc_gera_lista_portaria_capital_incompleta;
  --
  procedure prc_gera_lista_portaria_raj_completa(pcod_perito in number
                                                ,pdata_agendamento in date);
  --
  procedure prc_gera_lista_portaria_raj_incompleta;
  --
  procedure prc_gera_lista_portaria_cdp_completa(pcod_perito in number
                                                ,pdata_agendamento in date);
  --
  procedure prc_gera_lista_portaria_cdp_incompleta;
  --
  procedure prc_gera_lista_portaria_agendamento_externo_completa(pcod_perito in number
                                                                ,pdata_agendamento in date);
  --
  procedure prc_gera_lista_portaria_agendamento_externo_incompleto;
  --
end;
/