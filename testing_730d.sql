select
  cas_clientid,
  cas_aliasid,
  cas_file_number,
  max(alias_set) alias_set,
  max(client_set) client_set
from (
select
  cas_clientid,
  cas_aliasid,
  cas_file_number,
  1 as alias_set,
  0 as client_set
from cases
where cas_aliasid in (
  select distinct cas_aliasid
  from cases
  where cas_file_number in (
    select distinct dsp_file_number
    from dispositions
    where dsp_action = '730' or dsp_action = 'NGMD')
)

union

select
  cas_clientid,
  cas_aliasid,
  cas_file_number,
  0 as alias_set,
  1 as client_set
from cases
where cas_clientid in (
  select distinct cas_clientid
  from cases
  where cas_file_number in (
    select distinct dsp_file_number
    from dispositions
    where dsp_action = '730' or dsp_action = 'NGMD')
) order by cas_aliasid
) comparison
group by cas_clientid, cas_aliasid, cas_file_number
order by cas_file_number, client_set