--NG051539491
/*=========================================================================
                                Author: Kenny Moyer                                                                                                                                                                                                    
                                Server: RBTSQLBIV01                                                                                                                                                                                                      
                                Database: BI_Reporting                                                                                                                                                
                                Date Created: 07/02/2015                                                                                                                                                                            
                                Last Change:  10/29/2015
                                Last Change Desc: BSM - Opportunity Type was added for Pipeline Group                                                                                                                                                                                               
                                Description: Listing of Experian Advisor loans in current pipeline (includes Extensions and Modifications)
                                ID: 39491                                                                              
                                Added RealEstColl column. KCH 3/3/2020 
                                Modified KCH 4/2021
                                Modified Closed Date and Removed Result logic KCH 6/2021
                                Modified Stage Filter to exclude Stage 88.5 Declines/Withdrawals KCH 9/7/2021
===========================================================================*/

--DECLARE @Market AS VARCHAR(4) = 'GLM2'
--DECLARE @Officer_Department AS VARCHAR(500) = 'BCM'
--DECLARE @PipelineGroup AS VARCHAR(500) = 'New Pipeline'

SELECT
        [otm].[TeamMember] AS [Adding a change to this code]
      , [o].[PrimaryTeamMemberCode]
      , IIF(LEN( [OCD].[ReportingGroup] ) >= 1, [OCD].[ReportingGroup], 'No Officer Assigned') AS [Officer Department]
      , [o].[AccountNumber]
      , [o].[Key]
      , [o].[ProductType]
      , IIF([c].[IsEmployee] = '1', 'Bank Associate', [c].[FullNameList])                      AS [FullNameList]
      , [o].[TotalAmount]                                                                      AS [TotalAmt]
      , [o].[NewMoney]                                                                         AS [NewMoney]
      , [rate].[CurrentRate]                                                                   AS [currentrate]
      , [rate].[MinDate]
      , [o].[Stage]
      , [o].[MaturityPeriod]
                  ,XDH.Closed_Date AS ClosedDate --KCH 6/2021
                  ,XDH.DateClosedFieldUsed AS DateClosedFieldUsed --KCH 6/2021
                  --,IIF(o.Result = 'Won',XDH.Closed_Date,NULL) AS ClosedDate --KCH
                  --,IIF(o.Result = 'Won',XDH.DateClosedFieldUsed,NULL) AS DateClosedFieldUsed --KCH
      --, [o].[DispositionedDate]                                                                 AS [ClosedDate]
      , [o].[Result]
      , [o].[ResultCode]
      , [o].[Decision]
      , [o].[DecisionDate]
      , [o].[IsRenewal]
      , [o].[IsExtension]
      , [obd].[BDFDateTime2]                                                                   AS [BDFDate2_ApplicationDate]
      , [obd].[BDFString39]                                                                    AS [BDFString39_Market]
      , DATEDIFF( dd, CONVERT( DATE, [obd].[BDFDateTime2], 1 ), GETDATE( ))                    AS [DaysCalc]
        --,IIF(o.IsRenewal=1,'Extension/Modification',IIF(o.IsExtension=1,'Extension/Modification','New Pipeline')) AS PipelineGroup
        --BSM 10/29/2015 Change
      , CASE
            WHEN [o].[OriginationType] IN
                ( 'Extension', 'Modification', 'Renewal' ) THEN 'Extension/Modification'
            WHEN [o].[OriginationType] IN ( 'New' ) THEN 'New Pipeline'
            WHEN [o].[OriginationType] IN ( 'Review' ) THEN 'Annual Review'
            ELSE 'Not Assigned'
        END                                                                                    AS [PipeLineGroup]
      , IIF([bu].[Code] IS NULL, '9997', '0' + RIGHT([bu].[Code], 3))                          AS [Code]
      , [MDS_BC].[Horizon Code]
      , [MDS_BC].[Name]                                                                        AS [BCName]
      , [MDS_BC].[Region_Code]                                                                 AS [Market]
      , [MDS_Region].[Name]                                                                    AS [RegionName]
      , [MDS_Region].[Sort]                                                                    AS [RegionSort]
      , [bu].[Name]
      , CASE
            WHEN [o].[IsRenewal] = '1' THEN 'Ext/Mod'
            WHEN [o].[IsExtension] = '1' THEN 'Ext/Mod'
            ELSE 'Regular Pipeline'
        END                                                                                    AS [Pipeline Group]
                  , IIF([COLL].[KEY] IS NOT NULL, 'Y', 'N') AS RealEstCollKEY
FROM
        [BI_Reporting].[NG].[Opportunities]              [o]
    LEFT JOIN
        [BI_Reporting].[NG].[Clients]                    [c]
            ON [o].[ClientId]            = [c].[Id]

    LEFT JOIN
        [BI_Reporting].[NG].[OpportunityBankAssignments] [oba]
            ON [o].[Id]                  = [oba].[OpportunityId]
               AND  [oba].[Type]         = 'Branch'

    LEFT JOIN
        [BI_Reporting].[NG].[OpportunityTeamMembers]     [otm]
            ON [o].[Id]                  = [otm].[OpportunityId]
               AND  [otm].[IsPrimary]    = 1

    LEFT JOIN
        [BI_Reporting].[NG].[BusinessUnits]              [bu]
            ON [bu].[Id]                 = [oba].[BusinessUnitId] --AND bu.[Type] = 'Branch'

    LEFT JOIN
        [BI_Reporting].[NG].[OpportunityBankDefined]     [obd]
            ON [o].[Id]                  = [obd].[Id]

    LEFT JOIN
        (
            SELECT
                    [one].[OpportunityId]
                  , [one].[MinDate]
                  , [two].[CurrentRate]
            FROM    ((
                         SELECT
                                [OpportunityInterestRateSchedules].[OpportunityId]
                              , MIN( [OpportunityInterestRateSchedules].[EffectiveDate] ) AS [MinDate]
                         FROM   [BI_Reporting].[NG].[OpportunityInterestRateSchedules]
                         GROUP BY
                                [OpportunityInterestRateSchedules].[OpportunityId]
                     ) [one]
                INNER JOIN
                    (
                        SELECT
                                [OpportunityInterestRateSchedules].[OpportunityId]
                              , [OpportunityInterestRateSchedules].[CurrentRate]
                              , [OpportunityInterestRateSchedules].[EffectiveDate]
                        FROM    [BI_Reporting].[NG].[OpportunityInterestRateSchedules]
                    )  [two]
                        ON [one].[OpportunityId] = [two].[OpportunityId]
                           AND  [one].[MinDate] = [two].[EffectiveDate])
        )                                                [rate]
            ON [o].[Id]                  = [rate].[OpportunityId]

    LEFT JOIN
        [BI_Bank_MDS].[mdm].[BankingCenter_leaf]         [MDS_BC]
            ON [MDS_BC].[Horizon Code]   = IIF([bu].[Code] IS NULL, '9997', '0' + RIGHT([bu].[Code], 3))
               AND  [MDS_BC].[Bank_Code] <> 8

    LEFT JOIN
        [BI_Bank_MDS].[mdm].[Region_leaf]                [MDS_Region]
            ON [MDS_Region].[Code]       = [MDS_BC].[Region_Code]

    LEFT JOIN
        (
            SELECT
                    [OL].[Name]
                  , [OL].[OfficerCode]
                  , [OL].[ReportingName]
                  , [OL].[LastName]
                  , [OL].[FirstName]
                  , [OL].[ReportingGroup]
                  , [OL].[Tier]
                  , [OL].[HireDate]
                  , [OL].[TermDate]
                  , [OL].[Inactive_Code]
                  , [OL].[Inactive_Name]
                  , [OL].[Inactive_ID]
                  , [OL].[Exclude_Code]
                  , [OL].[Exclude_Name]
                  , [OL].[Exclude_ID]
                  , [OL].[EnterDateTime]
                  , [OL].[EnterUserName]
            FROM    [BI_Bank_MDS].[mdm].[Officer_Leaf] AS [OL]
            WHERE
                    [OL].[Bank_Code]                 <> 8
                    AND LEN( [OL].[ReportingGroup] ) >= 1
                    AND [OL].[Inactive_Code]         = 0
        )                                                AS [OCD]
            ON [OCD].[OfficerCode]       = [o].[PrimaryTeamMemberCode]

                LEFT JOIN [BI_Reporting].[ng].[DateHistory] XDH ON o.Id = XDH.ID AND XDH.IsActive = 1 --KCH

   OUTER APPLY 
                (SELECT TOP 1 C2.[KEY]
                FROM BI_Reporting.NG.Opportunities AS O2
                LEFT JOIN [BI_Reporting].NG.[OpportunityCollaterals] AS X2 ON X2.OpportunityID = O2.ID
                LEFT JOIN BI_Reporting.NG.Collateral AS C2 ON C2.ID = X2.ID
                WHERE O2.[KEY] = [o].[KEY] AND C2.CollateralTypeCode BETWEEN '710' AND '730' AND C2.CollateralTypeCode <> '720') COLL

WHERE
--        ([o].[Stage] NOT IN
--             ( 'Stage 1: Origination', 'Stage 13: Advisor File Completed', 'Stage 12.5 Booking', 'Stage 12: Post-Closing'
--             , 'Discussion', 'None', 'Stage 99: Duplicate', 'Stage 14:  HMDA/CRA Reviewed', 'Stage 88 - Withdraw Pending'
--             , 'Stage 88 - QC CML Review', 'Stage 88.5 Declines/Withdrawals')
        --)
                                --AND 
								[o].[Stage] IS NOT NULL
/*        ([o].[Stage] NOT IN
             ( 'Stage 1: Origination', 'Stage 13: Advisor File Completed', 'Stage 12: Post-Closing/Sent to Servicing'
             , 'Discussion', 'None', 'Stage 99: Duplicate', 'Stage 14:  HMDA/CRA Reviewed', 'Stage 88 - Withdraw Pending'
             )
        )*/
        AND [otm].[IsPrimary] = 1
        -- AND   o.Result IS NULL  Change 02/08/2016
        AND [o].[Result] IS NULL
        --AND oba.[Type] = 'Branch'
                                AND XDH.Closed_Date IS NULL --KCH 6/2021
        --AND [o].[DispositionedDate] IS NULL --Replaced with ClosedDate Filter Above KCH 6/2021
        --AND [MDS_BC].[Region_Code] IN ( @Market )
        --BSM 10/29/2015 Change
   --     AND CASE
   --             WHEN [o].[OriginationType] IN
   --                 ( 'Extension', 'Modification', 'Renewal' ) THEN 'Extension/Modification'
   --             WHEN [o].[OriginationType] IN ( 'New' ) THEN 'New Pipeline'
   --             WHEN [o].[OriginationType] IN ( 'Review' ) THEN 'Annual Review'
   --             ELSE 'Not Assigned'
   --         --END IN ( @PipelineGroup )
			

GROUP BY
        [otm].[TeamMember]
      , [o].[PrimaryTeamMemberCode]
      , [OCD].[ReportingGroup]
      , [o].[AccountNumber]
      , [o].[Key]
      , [o].[ProductType]
      , [c].[IsEmployee]
      , [c].[FullNameList]
      , [o].[TotalAmount]
      , [o].[NewMoney]
      , [rate].[CurrentRate]
      , [rate].[MinDate]
      , [o].[Stage]
      , [o].[MaturityPeriod]
                  ,XDH.Closed_Date --KCH 6/2021
                  ,XDH.DateClosedFieldUsed --KCH 6/2021
                  --,IIF(o.Result = 'Won',XDH.Closed_Date,NULL) --KCH
                  --,IIF(o.Result = 'Won',XDH.DateClosedFieldUsed,NULL) --KCH
      --, [o].[DispositionedDate]
      , [o].[Result]
      , [o].[ResultCode]
      , [o].[Decision]
      , [o].[DecisionDate]
      , [o].[IsRenewal]
      , [o].[IsExtension]
        --BSM 10/29/2015 Change
      , [o].[OriginationType]
      , [bu].[Code]
      , [bu].[Name]
      , [obd].[BDFDateTime2]
      , [obd].[BDFString39]
      , [MDS_BC].[Horizon Code]
      , [MDS_BC].[Name]
      , [MDS_BC].[Region_Code]
      , [MDS_BC].[Horizon Code]
      , [MDS_Region].[Name]
      , [MDS_Region].[Sort]
                  , IIF([COLL].[KEY] IS NOT NULL, 'Y', 'N')
ORDER BY
        [o].[Key];
