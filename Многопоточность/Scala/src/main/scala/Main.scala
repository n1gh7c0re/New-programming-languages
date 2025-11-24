import scala.io.Source
import java.io.{File, PrintWriter}
import java.util.concurrent.{Executors, Callable, ExecutorService}
import scala.jdk.CollectionConverters._
import ujson._

case class Report(chunk: Int, sum: Double, avg: Double, max: Double)

object Main {
  def main(args: Array[String]): Unit = {
    // Read config.json
    val cfgText = Source.fromFile("config.json").mkString
    val cfg = ujson.read(cfgText)
    val threads = cfg.obj.get("threads").map(_.num.toInt).getOrElse(4)
    val chunkSize = cfg.obj.get("chunk_size").map(_.num.toInt).getOrElse(1000)

    // Read CSV lines
    val lines = Source.fromFile("data.csv").getLines().filter(_.trim.nonEmpty).toVector
    val parsed = lines.map { line =>
      val parts = line.split(",", 2).map(_.trim)
      val id = parts(0).toLong
      val value = parts(1).toDouble
      (id, value)
    }

    val chunks = parsed.grouped(chunkSize).toVector
    val executor: ExecutorService = Executors.newFixedThreadPool(threads)

    val tasks = chunks.zipWithIndex.map { case (chunkData, idx) =>
      new Callable[String] {
        override def call(): String = {
          val values = chunkData.map(_._2)
          val sum = values.sum
          val avg = if (values.nonEmpty) values.sum / values.size else 0.0
          val max = if (values.nonEmpty) values.max else Double.NaN
          val report = Obj("chunk" -> idx, "sum" -> sum, "avg" -> avg, "max" -> max)
          val fname = s"report_chunk_${idx}.json"
          val pw = new PrintWriter(new File(fname))
          pw.println(ujson.write(report, 2))
          pw.close()
          fname
        }
      }
    }

    // run tasks
    val futures = executor.invokeAll(tasks.asJava)
    executor.shutdown()

    // read chunk files and combine
    val reports = chunks.indices.map { idx =>
      val fname = s"report_chunk_${idx}.json"
      val txt = Source.fromFile(fname).mkString
      ujson.read(txt)
    }

    // Scala 3 varargs splice: use reports* (instead of reports: _*)
    val output = ujson.Arr(reports*)
    val outpw = new PrintWriter(new File("reports.json"))
    outpw.println(ujson.write(output, 2))
    outpw.close()
    println(s"Wrote reports.json with ${reports.length} chunk reports.")
  }
}
