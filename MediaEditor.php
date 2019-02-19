<?php
/*
10.229.190.20/dev/MediaEditor.php?jobid=107&NoCheckUser=1&UriAudio=/home/MSF/development/users/1/media/test-fre.wav&UriXml=/home/MSF/development/users/1/result/test-fre.xml&IdUser=0
 * 
 *  */
require_once("../Toolbox/config.php");
require_once("../Toolbox/divers.php");
require_once("../Toolbox/database.php");


$JobId  = "";
$ShowSpeakers = false;
$smarty = DIV_InitSmarty();

/* * *************************************************************************
  SESSIONS
 * ************************************************************************* */
$Args  = DIV_ReadParamsHash();
if (!DIV_SessionOK($smarty, "login"))
{
	if (($Args["NoCheckUser"]!=1) && (isset($Args["UriAudio"])) && (isset($Args["UriXml"])))
	{
          exit;
	}
}
//firefox ne supporte plus les mp3
$PlayerExtention = "mp3";
if (strstr($_SERVER['HTTP_USER_AGENT'] , "Firefox") !== false)
  $PlayerExtention = "ogg";

/* * *************************************************************************
  LECTURE DES PARAMETRES
 * ************************************************************************* */
//on lit le job id passé en paramètre   
$Args  = DIV_ReadParamsHash();
if (isset($Args["jobid"]))
    $JobId = $Args["jobid"];
else
{
    $smarty->assign("MessageDeRetour", "Wrong parameter");
    $smarty->display('MediaEditor.tpl');
    exit;
}
if (isset($DisablePlayer))
{
    $smarty->assign("MessageDeRetour", "Player disabled");
    $smarty->display('MediaEditor.tpl');
    exit;
}


//LOG_Write(print_r($Args, true));      
//LOG_Write(print_r($_SESSION, true));      

  if (($_SESSION['Role'] == "A") || isset($Args["IdUser"]))
{
      $IdUser = $Args["IdUser"];
	LOG_Write(print_r($IdUser, true));
}
  else
      $IdUser = $_SESSION['IdUser'];

LOG_Write(__FUNCTION__. " IdUser=$IdUser, JobId=$JobId");
  
if (((DB_IsJobToUser($JobId, $IdUser) == RET_OK) || ($_SESSION['Role'] == "A"))
        || (( isset($Args["NoCheckUser"]) && ($Args["NoCheckUser"]==1)) && (isset($Args["UriAudio"]) &&  isset($Args["UriXml"])) ))
{
    //LOG_Write(print_r($_SESSION, true));   

    //on affiche ou pas les speakers
    if (isset($Args["ShowSpeakers"]))
        $ShowSpeakers=true;
    
    
    $Data = DB_GetJobStatus($IdUser, $JobId);
    $Ext  = DIV_GetExtension($Data['audiofile']);

    //on va convertir en mp3 car c'est lisible 
    $NomUtf8           = DIV_ConvertFilename($Data['audiofile']);
    $user_working_path = "$msf_user/$IdUser/" . CST_DIR_WORKING . "/";
    $user_audio_path   = "$msf_user/$IdUser/" . CST_DIR_MEDIA . "/";
    $results_path      = "$msf_user/$IdUser/" . CST_DIR_RESULT . "/";

    
    $bPlayAfterConvert= false;
    //$Args["UriAudio"]  = /path_to/to/file.xml
    if (isset($Args["UriAudio"]) &&  isset($Args["UriXml"]))
    {
        copy($Args["UriAudio"], "$user_audio_path/$NomUtf8");
        copy($Args["UriXml"], "$results_path$JobId.xml");
        
        //on force la conversion de wav en mp3 ou ogg
       /* voir si ça marche avec les wav avant de décommenter
        $Args["function"] = "convert";
        $bPlayAfterConvert= true;*/
    }
    
    //on récupère le chemin d'accès du fichier xml
    $srcFichierXml = "$user_working_path$JobId.xml";
    if (!file_exists($srcFichierXml))
        if (file_exists("$results_path$JobId.xml"))
            $srcFichierXml = "$results_path$JobId.xml";
    
    LOG_Write($Args);
    if ((isset($Args["function"])) && (strcmp($Args["function"], "ModifyText") == 0))
    {
        if (isset($Args['EditedText']))
        {
            $SizeOrig = filesize($srcFichierXml);
            if ($SizeOrig == 0)
                exit;

            $srcFichierEdite  = $user_working_path . $Data['idprocess'] . ".edited";
            $srcFichierMerged = $user_working_path . $Data['idprocess'] . ".merged";

            $Text = str_replace("&nbsp;", " ", $Args['EditedText']);
            $Text = str_replace("<br>", "\n", $Text);
            $Text = str_replace("</br>", "\n", $Text);

            $Text = strip_tags($Text);

            if (file_exists($srcFichierEdite))
                unlink($srcFichierEdite);

            file_put_contents($srcFichierEdite, $Text);
            LOG_Write(print_r($Args['EditedText'], true));
            // on genere le fichier xml avec les deux fichiers :
            // $srcFichierXml $srcFichierEdite

            $Cmd = "$msf_scripts/align_edition.pl -hyp $srcFichierXml -ref $srcFichierEdite -ofile $srcFichierMerged";
            putenv("OPT_SCRIPTS=$msf_scripts");
            $Ret = DIV_Exec($Cmd);
            LOG_Write($Cmd);
            LOG_Write(print_r($Ret, true));


            //taille a varié de moins de 50% bon !
            if (file_exists($srcFichierMerged))
            {
                $SizeNew    = filesize($srcFichierMerged);
                $SizeChange = abs($SizeNew - $SizeOrig) / $SizeOrig;

                if ($SizeChange < 0.5)
                {
                    //on remplace le xml par le .merged
                    if (file_exists($srcFichierXml . ".bak"))
                        unlink($srcFichierXml . ".bak");

                    rename($srcFichierXml, $srcFichierXml . ".bak");
                    rename($srcFichierMerged, $srcFichierXml);
                    echo "1";
                }
                else
                    echo "0";
            }
            else
                echo "0";
        }
        else
            echo "0";

        flush();
        exit;
    }
    //on fait juste la conversion en mp3
    if ((isset($Args["function"])) && (strcmp($Args["function"], "convert") == 0))
    {
      LOG_Write("convert");
        $Output = DIV_ReplaceExtension(str_replace('/', '_', str_replace(' ', '_', $NomUtf8)), "$PlayerExtention");
//on force le réencodage car si on a des liens youtube le nom devient identique 
//pour tous les fichiers
        if (true)
        { //-V 9 -b 48
            //on mets .wav car la transcription l'a généré !
            if (file_exists("$user_working_path/$NomUtf8.MSF.wav"))
            {
              $Cmd = "/usr/bin/ffmpeg -y -i '$user_working_path/$NomUtf8.MSF.wav' $user_working_path/$Output";
            }
            else
            {
              $Cmd = "/usr/bin/ffmpeg -y -i '$user_audio_path/$NomUtf8' $user_working_path/$Output";
            }
            LOG_Write($Cmd);
            $Ret= exec($Cmd);
            LOG_Write($Ret);
        }
        else
        {
            LOG_Write("No encoding done, the file $user_working_path/$Output already exists");
        }
        if (!$bPlayAfterConvert)
            exit;
    }


    if (!in_array(strtolower(DIV_GetExtension(str_replace('/', '_', str_replace(' ', '_', $NomUtf8)))), $ExtensionsJwPlayer))
    {
        $Output = DIV_ReplaceExtension(str_replace('/', '_', str_replace(' ', '_', $NomUtf8)), "$PlayerExtention");
        $smarty->assign("DoConvert", 1); //jquery lancera la conversion
        $smarty->assign("PleaseWait", DIV_Translate("PleaseWait")); //jquery lancera la conversion
    }
    else
    {
        $Output = str_replace('/', '_', str_replace(' ', '_', $NomUtf8));
        $smarty->assign("DoConvert", 0); //jquery lancera la conversion
    }

    //fait un lien dans le répertoire tmp du web vers le compte client VERS WORKING
    $lnkAudioPath = DIV_CreateWebAudioAndResultsPathTempLink($IdUser);
    if (isset($lnkAudioPath))
    {
      $smarty->assign("Media", "./" . $web_temp . "A_$lnkAudioPath/" . $NomUtf8);
      $smarty->assign("MediaMp3", "./" . $web_temp . "W_$lnkAudioPath/" . DIV_ReplaceExtension($Output, "$PlayerExtention"));
    }

    //on va mettre certains mots en gras
    if (isset($Args["Highlight"]))
      $Highlight=$Args["Highlight"];
    else
      $Highlight= "";
    
    //echo $srcFichierXml;
    $Xml       = DIV_Xml2WebPLayer($srcFichierXml, $ShowSpeakers, $Highlight);
    $Lang      = $Xml["lang"];
    $SubTitles = $Xml["text"];

    if (file_exists($srcFichierXml))
    {
      $smarty->assign("Xml", file_get_contents($srcFichierXml));
    }
    else
      $smarty->assign("MessageDeRetour", DIV_Translate("NoResult"));
    
    $smarty->assign("SubTitles", $SubTitles);
    $smarty->assign("Lang", $Lang);
    if (strcmp($Lang, "ara") == 0)
        $smarty->assign("Dir", "rtl");
    else
        $smarty->assign("Dir", "ltr");

    $smarty->assign("jobid", $JobId);
    $smarty->assign("IdUser", $IdUser);
    $smarty->assign("ShowSpeakers", $ShowSpeakers);

    if (isset($Data['datesubmit']))
      $smarty->assign("DateSubmit", $Data['datesubmit']);
    if (isset($Data['execaudiotype']))
      $smarty->assign("ExecAudioType", $Data['execaudiotype']);
    if (isset($Data['execlanguage']))
      $smarty->assign("ExecLanguage", $Data['execlanguage']);

    $smarty->assign("username", $Data['username']);


    if (isset($Data['audiofile']))
      $smarty->assign("AudioFileName", $Data['audiofile']);

    if (isset($DisablePlayer))
        $smarty->assign("DisablePlayer", $DisablePlayer  );
    else
        $smarty->assign("DisablePlayer", 0  );

    $smarty->display('MediaEditor.tpl');
}
else
{
    echo "access denied";
}
?>


