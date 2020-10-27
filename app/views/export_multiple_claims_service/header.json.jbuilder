json.data do
  json.multipleName respondent_name
  json.multipleSource 'ET1 Online'
  json.multipleReference primary_reference
  json.caseIdCollection(case_references) do |case_ref|
    json.id nil
    json.value do
      json.ethos_CaseReference case_ref
    end
  end
end
json.event do
  json.id "createMultiple"
  json.summary ""
  json.description ""
end
json.event_token event_token
json.ignore_warning false
json.draft_id nil
