remotes::install_github("OHDSI/Hydra")
outputFolder <- "d:/temp/output"  # location where you study package will be created


########## Please populate the information below #####################
version <- "v0.1.0"
name <- "Acute Liver Failure - an OHDSI network study"
packageName <- "AcuteLiverFailure"
skeletonVersion <- "v0.0.1"
createdBy <- "rao@ohdsi.org"
createdDate <- Sys.Date() # default
modifiedBy <- "rao@ohdsi.org"
modifiedDate <- Sys.Date()
skeletonType <- "CohortDiagnosticsStudy"
organizationName <- "OHDSI"
description <- "Cohort diagnostics on Acute Liver Failure cohorts."


cohortIds <- c(309, 310)

# Fetch approved cohort definition----------------------------------
# from atlas-phenotype.ohdsi.org (note: approved phenotypes do not have '[')
baseUrl <- "https://atlas-phenotype.ohdsi.org/WebAPI"
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = "db",
  webApiUsername = keyring::key_get("ohdsiAtlasPhenotypeUser"),
  webApiPassword = keyring::key_get("ohdsiAtlasPhenotypePassword")
)

webApiCohorts <- ROhdsiWebApi::getCohortDefinitionsMetaData(baseUrl = baseUrl)
studyCohorts <-  webApiCohorts |>
  dplyr::filter(stringr::str_detect(string = tolower(name),
                                    patter = "liver|hepatic")) |> 
  dplyr::filter(stringr::str_detect(string = tolower(name),
                                    patter = "injury|failure"))

################# end of user input ##############

# compile them into a data table
cohortDefinitionsArray <- list()
for (i in (1:nrow(studyCohorts))) {
  cohortDefinition <-
    ROhdsiWebApi::getCohortDefinition(cohortId = studyCohorts$id[[i]],
                                      baseUrl = baseUrl)
  cohortDefinitionsArray[[i]] <- list(
    id = studyCohorts$id[[i]],
    createdDate = studyCohorts$createdDate[[i]],
    modifiedDate = studyCohorts$createdDate[[i]],
    logicDescription = studyCohorts$description[[i]],
    name = stringr::str_trim(stringr::str_squish(cohortDefinition$name)),
    expression = cohortDefinition$expression
  )
}

tempFolder <- tempdir()
unlink(x = tempFolder, recursive = TRUE, force = TRUE)
dir.create(path = tempFolder, showWarnings = FALSE, recursive = TRUE)

specifications <- list(id = 1,
                       version = version,
                       name = name,
                       packageName = packageName,
                       skeletonVersion = skeletonVersion,
                       createdBy = createdBy,
                       createdDate = createdDate,
                       modifiedBy = modifiedBy,
                       modifiedDate = modifiedDate,
                       skeletonType = skeletonType,
                       organizationName = organizationName,
                       description = description,
                       cohortDefinitions = cohortDefinitionsArray)

jsonFileName <- paste0(file.path(tempFolder, "CohortDiagnosticsSpecs.json"))
write(x = specifications |> RJSONIO::toJSON(pretty = TRUE, digits = 23), file = jsonFileName)


##############################################################
##############################################################
#######       Get skeleton from github            ############
#######       Uncomment if you want to use latest ############
#######       skeleton only - for advanced user   ############
##############################################################
##############################################################
##############################################################
#### get the skeleton from github
download.file(url = "https://github.com/OHDSI/SkeletonCohortDiagnosticsStudy/archive/refs/heads/main.zip",
              destfile = file.path(tempFolder, 'skeleton.zip'))
unzip(zipfile =  file.path(tempFolder, 'skeleton.zip'),
      overwrite = TRUE,
      exdir = file.path(tempFolder, "skeleton")
)
fileList <- list.files(path = file.path(tempFolder, "skeleton"), full.names = TRUE, recursive = TRUE, all.files = TRUE)
DatabaseConnector::createZipFile(zipFile = file.path(tempFolder, 'skeleton.zip'),
                                 files = fileList,
                                 rootFolder = list.dirs(file.path(tempFolder, 'skeleton'), recursive = FALSE))

##############################################################
##############################################################
#######               Build package              #############
##############################################################
##############################################################
##############################################################


#### Code that uses the ExampleCohortDiagnosticsSpecs in Hydra to build package
hydraSpecificationFromFile <- Hydra::loadSpecifications(fileName = jsonFileName)
unlink(x = outputFolder, recursive = TRUE)
dir.create(path = outputFolder, showWarnings = FALSE, recursive = TRUE)


# for advanced user using skeletons outside of Hydra
Hydra::hydrate(specifications = hydraSpecificationFromFile,
               outputFolder = outputFolder,
               skeletonFileName = file.path(tempFolder, 'skeleton.zip')
)


unlink(x = tempFolder, recursive = TRUE, force = TRUE)


##############################################################
##############################################################
######       Build, install and execute package           #############
##############################################################
##############################################################
##############################################################

