/**
@description     :An Apex Class for Retrieving Questionnaire Records those status is in Completed
                  and expired.we are using this apex class in LWCs such as 
				  biPspbQualitativeCompletedQuestionnaire2,  biPspbQualitativeCompletedQuestionnaire,
				  biPspbWapiCompletedQuestionnaire,biPspbPSSCompletedQuestionnaires, 
				  biPspbDlqiCompletedQuestionnaire.
* History:
* Version	Author		Date			Detail			Description
* 1.0		Abinsha		05-Dec-2023		Created			Initial development.
* 1.1		Abinsha 	01-Jan-2024		Updated			Updated for caregiver.
* 1.2		Abinsha		04-Apr-2024		Updated			Catch log added.
*/

public with sharing class BI_PSP_CompletedQuestionnaireCtrl {
    //Holds the condition to be addedd to the query.
    private static String conditions;
    //this variable holds a list of assessment response records.
    private static List<AssessmentQuestionResponse> listOFres;
    //holds the enrollee record id.
    private static string enrolleeId;
    //holds the responses of an assessment which got completed or expired.
    private static List<AssessmentQuestionResponse> assessmentResponses;

    /**
 * @description Constructs a dynamic SOQL `WHERE` clause based on the provided parameters.
 * The method includes conditions for `categoryName`, `enrolleeId`, `targetDate`, and optional flags 
 * for two-month and fourteen-week assessments.
 * @param categoryName The category name of the questionnaire.
 * @param enrolleeId The ID of the enrollee to filter the query.
 * @param targetDate The target date to filter the query.
 * @param twoMonths If true, includes a condition for two-month assessments.
 * @param fourteenWeeks If true, includes a condition for fourteen-week assessments.
 * @return A string representing the dynamically constructed SOQL `WHERE` clause.
 */
    public static String buildConditions(String categoryName,String enrolleeId, String targetDate, Boolean twoMonths, Boolean fourteenWeeks) {
        String conditions = 'Assessment.BI_PSP_CareProgramEnrollee__c = \'' + enrolleeId + '\'';
        
        if (categoryName != null && !String.isBlank(categoryName)) {
            conditions += ' AND BI_PSP_Questionnaire_Name__c = \'' + categoryName + '\'';
        }
        if (targetDate != null && !String.isBlank(targetDate)) {
            conditions += ' AND Assessment.BI_PSP_DateForCQ__c = \'' + targetDate + '\'';
        }
        if (twoMonths) {
            conditions += ' AND BI_PSP_QsqAfter2months__c = \'' + BI_PSP_QuestionnaireConstant.pageOne + '\'';
        }
        if (fourteenWeeks) {
            conditions += ' AND BI_PSP_QsqAfterWeeks__c = \'' + BI_PSP_QuestionnaireConstant.pageTwo + '\'';
        }
        conditions += ' AND Assessment.AssessmentStatus != \'' + BI_PSP_QuestionnaireConstant.inprogress + '\'';
        
        return conditions;
    }
    /**
 * @description Retrieves completed questionnaire responses for a given enrollee based on the target date and category name.
 * This method is cacheable to improve performance and reduce server load.
 * @param targetDate The target date to filter the completed questionnaires.
 * @param categoryName The category name to filter the completed questionnaires.
 * @return A list of AssessmentQuestionResponse records that match the provided criteria.
 */
    @AuraEnabled(cacheable=true)
    public static List<AssessmentQuestionResponse> getCompletedQuestionares(String targetDate, String categoryName) {
        List<AssessmentQuestionResponse> assessmentResponses = new List<AssessmentQuestionResponse>();
        String enrolleeId;
        try {
            enrolleeId = BI_PSP_CurrentUser.getEnrolleeRecords()[0].Id;
            if (enrolleeId != null && !String.isBlank(enrolleeId)) {
                // Build conditions
                String conditions = buildConditions(categoryName, enrolleeId, targetDate, false, false);
                
                // Include the ORDER BY clause in conditions
                conditions += ' ORDER BY CreatedDate DESC';

                // Define fields for the query
                String fields = 'Id, AssessmentQuestion.QuestionText, ResponseText, ResponseValue, BI_PSP_Questionnaire_Name__c, Assessment.Id, Assessment.EffectiveDateTime, Assessment.BI_PSP_RolloutforCompletedQuestionnarie__c, BI_PSP_ResponseOrder__c, Assessment.BI_PSP_DateForCQ__c';

                // Execute the query using the common query method
                List<SObject> sObjectResponses = BI_PSP_CommonQueryUtility.executeQuery('AssessmentQuestionResponse', fields, conditions, false);

                // Cast the result to List<AssessmentQuestionResponse>
                for (SObject sObj : sObjectResponses) {
                    assessmentResponses.add((AssessmentQuestionResponse) sObj);
                }
            } else {
                BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.emptyCategoryName, BI_PSP_CompletedQuestionnaireCtrl.class.toString(), true, BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
            }
            if (assessmentResponses.isEmpty()) {
                BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.emptyAssesment, BI_PSP_CompletedQuestionnaireCtrl.class.toString(), false, BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
            }
        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.exceptionLogMessage('', BI_PSP_CompletedQuestionnaireCtrl.class.toString(), ex);
        }
        return assessmentResponses;
    }

    /**
 * @description Retrieves completed assessments for the current user based on the specified category name.
 * The method returns a list of `Assessment` records and is cacheable to improve performance.
 * @param categoryName The name of the category to filter the assessments.
 * @return A list of `Assessment` records that match the provided category name and are associated with the current user's enrollee ID.
 */
   @AuraEnabled(cacheable=true)
    public static List<Assessment> getQstnrcurrentcompleteddate(String categoryName) {
        List<Assessment> assessmentResponses = new List<Assessment>();
        try {
            // Fetch the enrollee ID
            String enrolleeId = BI_PSP_CurrentUser.getEnrolleeRecords()[0].Id;

            if (!String.isBlank(categoryName) && !String.isBlank(enrolleeId)) {
                // Build the conditions for the query
                String conditions = 'Name = \'' + categoryName + '\' AND BI_PSP_CareProgramEnrollee__c = \'' + enrolleeId + '\'';

                // Add Order by clause to the conditions
                String orderByClause = ' ORDER BY CreatedDate DESC';
                conditions += orderByClause;

                // Fields to retrieve
                String fields = 'Id, Name, EffectiveDateTime, ExpirationDateTime';

                // Execute the query using the common query utility method
                assessmentResponses = (List<Assessment>)BI_PSP_CommonQueryUtility.executeQuery(
                    'Assessment', fields, conditions, false
                );
            } else {
                // Log error for missing category name or enrollee ID
                BI_PSP_LogMessagesUtility.logError(
                    BI_PSP_QuestionnaireConstant.emptyCategoryName,
                    BI_PSP_CompletedQuestionnaireCtrl.class.toString(),
                    true,
                    BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR
                );
            }

            if (assessmentResponses.isEmpty()) {
                // Log error if no assessments are found
                BI_PSP_LogMessagesUtility.logError(
                    BI_PSP_QuestionnaireConstant.emptyQuestioniareResponse,
                    BI_PSP_CompletedQuestionnaireCtrl.class.toString(),
                    false,
                    BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR
                );
            }
        } catch (Exception ex) {
            // Log any exceptions encountered during execution
            BI_PSP_LogMessagesUtility.exceptionLogMessage(
                '',
                BI_PSP_CompletedQuestionnaireCtrl.class.toString(),
                ex
            );
        }
        return assessmentResponses;
    }
   /**
 * @description Retrieves a list of completed AssessmentQuestionResponse records for a given enrollee, focusing on questionnaires completed two months after the specified target date.
 * The method is cacheable to improve performance.
 * @param targetDate The target date used to filter the questionnaires.
 * @return A list of AssessmentQuestionResponse records that match the criteria.
 */
   @AuraEnabled(cacheable=true)
public static List<AssessmentQuestionResponse> getQSQCompletedQuestionaresTwoMonths(
    String targetDate
) {
    List<AssessmentQuestionResponse> assessmentResponses = new List<AssessmentQuestionResponse>();
    try {
        enrolleeId = BI_PSP_CurrentUser.getEnrolleeRecords()[0].id;
        if (
            (targetDate != null && !String.isBlank(targetDate)) &&
            (enrolleeId != null && !String.isBlank(enrolleeId))
        ) {
           // Build conditions using the provided method
            String conditions = buildConditions(
                BI_PSP_QuestionnaireConstant.qualiCategory, 
                enrolleeId, 
                targetDate, 
                true, 
                false
            );
            
            // Specify fields to retrieve
            String fields = 'Id, AssessmentId, AssessmentQuestionId, AssessmentQuestion.QuestionText, ' +
                            'ResponseText, ResponseValue, BI_PSP_Questionnaire_Name__c, ' +
                            'Assessment.Id, Assessment.Name, Assessment.AssessmentStatus, ' +
                            'Assessment.BI_PSP_DateForCQ__c, Assessment.EffectiveDateTime, ' +
                            'Assessment.BI_PSP_RolloutforCompletedQuestionnarie__c, ' +
                            'BI_PSP_QsqAfter2months__c, BI_PSP_QsqAfterWeeks__c, BI_PSP_ResponseOrder__c';
                            
            // Specify whether to enforce sharing rules
            Boolean withSharingKeywrd = false;
            
            // Add the order by clause to the conditions
            String orderByClause = 'ORDER BY CreatedDate DESC, BI_PSP_ResponseOrder__c ASC';
            conditions += ' ' + orderByClause;
            
            // Execute the query using the common query method
            List<SObject> sObjectResponses = BI_PSP_CommonQueryUtility.executeQuery(
                'AssessmentQuestionResponse', 
                fields, 
                conditions, 
                withSharingKeywrd
            );
            
            // Cast the SObject list to List<AssessmentQuestionResponse>
            for (SObject sObj : sObjectResponses) {
                assessmentResponses.add((AssessmentQuestionResponse) sObj);
            }
            
            if (assessmentResponses.isEmpty()) {
                BI_PSP_LogMessagesUtility.logError(
                    BI_PSP_QuestionnaireConstant.emptyQuestioniareResponse, 
                    BI_PSP_CompletedQuestionnaireCtrl.class.toString(), 
                    false,
                    BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR
                );
            }
        } else {
            BI_PSP_LogMessagesUtility.logError(
                BI_PSP_QuestionnaireConstant.emptyEnrolleRecrd, 
                BI_PSP_CompletedQuestionnaireCtrl.class.toString(), 
                true,
                BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR
            );
        }
    } catch (Exception ex) {
        BI_PSP_LogMessagesUtility.exceptionLogMessage(
            '', 
            BI_PSP_CompletedQuestionnaireCtrl.class.toString(), 
            ex
        );
    }
    return assessmentResponses;
}

    /**
 * @description Retrieves a list of expired assessments that correspond to questionnaires completed two months after the specified event.
 * The method first queries `AssessmentQuestionResponse` records based on specific conditions, then uses those results to fetch the associated `Assessment` records.
 * @return A list of `Assessment` records that match the criteria.
 */
    @AuraEnabled(cacheable=true)
    public static List<Assessment> getQSQExpiredQuestionnaireTwoMonths() {
        List<Assessment> assessmentResponses = new List<Assessment>();
        try {
          	enrolleeId =BI_PSP_CurrentUser.getEnrolleeRecords()[0].id;
            // Query AssessmentQuestionResponses records
            /* USER_MODE is not used because AssessmentQuestionResponse is an Salesforce Industry object
             using Healthcare license*/
			 // Query AssessmentQuestionResponses records
         String conditions = 'BI_PSP_QsqAfter2months__c = \'' + BI_PSP_QuestionnaireConstant.pageOne + '\'';
        
        // Fields to retrieve
        String fields = 'Id, BI_PSP_QsqAfterWeeks__c, AssessmentId, BI_PSP_QsqAfter2months__c';
        
        // Execute the query using the common query utility method
        List<SObject> listOFres = BI_PSP_CommonQueryUtility.executeQuery(
            'AssessmentQuestionResponse',
            fields,
            conditions,
            false
        );
        // Create a set to store the IDs of AssessmentQuestionResponses records
        Set<Id> responseIds = new Set<Id>();
        if (!listOFres.isEmpty()) {
            for (SObject sObj : listOFres) {
                AssessmentQuestionResponse response = (AssessmentQuestionResponse) sObj;
                responseIds.add(response.AssessmentId);
            }
        } else {
            BI_PSP_LogMessagesUtility.logError(
                BI_PSP_QuestionnaireConstant.emptyQuestioniareResponse,
                BI_PSP_CompletedQuestionnaireCtrl.class.toString(),
                false,
                BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR
            );
        }

            // Query Assessment records using the IDs of AssessmentQuestionResponses
            /* USER_MODE is not used because Assessment is an Salesforce Industry object
             using Healthcare license*/
            if (
                (enrolleeId != null && !String.isBlank(enrolleeId)) &&
                (responseIds != null && !responseIds.isEmpty())
            ) {
               List<String> fieldsList = new List<String>{
        'Id',
        'Name',
        'EffectiveDateTime',
        'ExpirationDateTime'
    };
    // Convert List<String> to a comma-separated string
    String responseIdsStr = '\'' + String.join(responseIds, '\', \'') + '\'';

    // Construct the dynamic query
    String query = 'SELECT ' + String.join(fieldsList, ', ') + 
                   ' FROM Assessment' +
                   ' WHERE Name = \'' + BI_PSP_QuestionnaireConstant.qualiCategory + '\'' +
                   ' AND BI_PSP_CareProgramEnrollee__c = \'' + enrolleeId + '\'' +
                   ' AND Id IN (' + responseIdsStr + ')' + 
                   ' ORDER BY CreatedDate DESC';
// Execute the query
List<SObject> queryResponse = BI_PSP_CommonQueryUtility.executeComplexQuery(query, false);
assessmentResponses = (List<Assessment>) queryResponse;
                
            } else {
               BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.emptyEnrolleRecrd,BI_PSP_CompletedQuestionnaireCtrl.class.toString(),true,BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
            }
             if (assessmentResponses.isEmpty()) {
                BI_PSP_LogMessagesUtility.logError(BI_PSP_QuestionnaireConstant.emptyQuestioniareResponse,BI_PSP_CompletedQuestionnaireCtrl.class.toString(),false,BI_PSP_QuestionnaireConstant.LOG_SEVERITY_ERROR);
               
            }
        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.exceptionLogMessage('',BI_PSP_CompletedQuestionnaireCtrl.class.toString(),ex);
        }
        return assessmentResponses;
    }
}